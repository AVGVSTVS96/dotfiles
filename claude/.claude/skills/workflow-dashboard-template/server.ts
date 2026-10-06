import { closeSync, existsSync, openSync, readdirSync, readFileSync, readSync, statSync } from "node:fs"
import { homedir } from "node:os"
import { basename, join } from "node:path"

type Kind = "note" | "ran" | "wrote" | "edited" | "read" | "searched" | "spawned" | "failed" | "finished"
type Activity = { at: string; lead: string; kind: Kind; text: string }
type Pending = { kind: Kind; text: string; command: string; at: string }
type Worker = { id: string; description: string; status: "running" | "done"; tokens: number | null }
type ToolInput = Partial<Record<"description" | "command" | "file_path" | "query" | "url", string>>
type Block =
  | { type: "text"; text: string }
  | { type: "tool_use"; id: string; name: string; input: ToolInput }
  | { type: "tool_result"; tool_use_id: string; is_error?: boolean; content: unknown }
  | { type: "thinking" }
type Usage = { input_tokens: number; output_tokens: number; cache_read_input_tokens: number; cache_creation_input_tokens: number }
type Line = { type: string; timestamp?: string; cwd?: string; message?: { content?: Block[] | string; usage?: Usage } }
type JournalEvent = { type: string; agentId?: string; label?: string; phase?: string; result?: unknown }
type Lead = {
  id: string
  label: string
  phase: string
  cwd: string
  remotes: Set<string>
  startedAt: string | null
  lastAt: string | null
  context: number
  contextSeries: [number, number][]
  output: number
  counts: Partial<Record<Kind, number>>
  busyMs: Partial<Record<Kind, number>>
  events: [number, Kind][]
  files: Map<string, { n: number; at: string; kind: Kind }>
  note: string
  prompt: string
  workers: Map<string, Worker>
  activity: Activity[]
  tools: Map<string, Pending>
  result: unknown
  offset: number
}

const STALL_MS = 10 * 60_000
const GAP_MS = 60_000
const KEEP = 60
const SERIES_POINTS = 160
const BRIEF_CHARS = 2400
const home = homedir()
const projects = join(home, ".claude/projects")

const newestFirst = (pattern: string) =>
  [...new Bun.Glob(pattern).scanSync({ cwd: projects })].map(p => join(projects, p)).sort((a, b) => statSync(b).mtimeMs - statSync(a).mtimeMs)

const run = process.argv[2]
const dir = run?.includes("/") ? run : newestFirst(`*/*/subagents/workflows/${run ?? "wf_*"}/journal.jsonl`).map(p => join(p, ".."))[0]
if (!dir) throw new Error(`no workflow run ${run ?? ""} under ~/.claude/projects`)
const runId = basename(dir)
const session = join(dir, "../../..")

const readScript = () => {
  if (process.env.SCRIPT) return readFileSync(process.env.SCRIPT, "utf8")
  const record = join(session, "workflows", `${runId}.json`)
  if (existsSync(record)) return String(JSON.parse(readFileSync(record, "utf8")).script ?? "")
  const scripts = newestFirst(`*/${basename(session)}/workflows/scripts/*.js`)
  const own = scripts.find(p => p.endsWith(`-${runId}.js`)) ?? scripts[0]
  return own ? readFileSync(own, "utf8") : ""
}

const script = readScript()
const meta = script.match(/export const meta\s*=\s*\{[\s\S]*?\n\}/)?.[0] ?? ""
const field = (source: string, key: string) => source.match(new RegExp(`\\b${key}:\\s*(["'\`])(.*?)\\1`))?.[2]
const PHASES = [...meta.matchAll(/\{([^{}]*)\}/g)].flatMap(([, body]) => {
  const title = field(body, "title")
  return title ? [{ title, detail: field(body, "detail") ?? "" }] : []
})

const HOST = process.env.HOST ?? "127.0.0.1"
const TITLE = process.env.TITLE ?? field(meta, "name") ?? runId
const DECISIONS = process.env.DECISIONS ?? ""
const CONTEXT_CAP = Number(process.env.CONTEXT_CAP ?? 400_000)
const SSH = /(?:^|[\s;&|(])ssh(?:\s+-[46AaCfGgKkMNnqsTtVvXxYy]+|\s+-[BbcDEeFIiJLlmOoPpRSWw]\s*\S+)*\s+(?:[\w.-]+@)?([\w.-]+)/

const parseLine = <T>(line: string): T[] => {
  try {
    return [JSON.parse(line)]
  } catch {
    return []
  }
}

const readFrom = <T>(path: string, offset: number) => {
  const size = statSync(path).size
  if (size <= offset) return { lines: [] as T[], offset }
  const buf = Buffer.alloc(size - offset)
  const fd = openSync(path, "r")
  readSync(fd, buf, 0, buf.length, offset)
  closeSync(fd)
  const end = buf.lastIndexOf(10)
  if (end < 0) return { lines: [] as T[], offset }
  return { lines: buf.subarray(0, end).toString("utf8").split("\n").flatMap(l => parseLine<T>(l)), offset: offset + end + 1 }
}

const oneLine = (s = "", max = 150) => {
  const t = s.replace(/\s+/g, " ").trim()
  return t.length > max ? `${t.slice(0, max - 1)}…` : t
}

const shortPath = (p = "", depth = 3) => p.replace(home, "~").split("/").slice(-depth).join("/")

const resultText = (content: unknown) =>
  typeof content === "string"
    ? content
    : Array.isArray(content)
      ? content.map(c => (typeof c === "object" && c && "text" in c ? String(c.text) : "")).join(" ")
      : ""

const describeTool = (name: string, input: ToolInput): [Kind, string, string] | null => {
  switch (name) {
    case "Bash":
      return ["ran", oneLine(input.description || input.command), oneLine(input.command, 400)]
    case "Write":
      return ["wrote", shortPath(input.file_path), input.file_path ?? ""]
    case "Edit":
      return ["edited", shortPath(input.file_path), input.file_path ?? ""]
    case "Read":
      return ["read", shortPath(input.file_path), input.file_path ?? ""]
    case "WebSearch":
      return ["searched", oneLine(input.query), input.query ?? ""]
    case "WebFetch":
      return ["read", oneLine(input.url), input.url ?? ""]
    case "Agent":
    case "Task":
      return ["spawned", oneLine(input.description), ""]
    default:
      return null
  }
}

const headline = (result: unknown) =>
  typeof result === "string"
    ? result
    : typeof result === "object" && result
      ? String(("headline" in result && result.headline) || ("summary" in result && result.summary) || ("notes" in result && result.notes) || "")
      : ""

const summarize = (result: unknown) => oneLine(headline(result).replace(/^#+\s*/gm, ""), 200) || "finished"

const leads = new Map<string, Lead>()
let journalOffset = 0

const ensure = (id: string) => {
  const existing = leads.get(id)
  if (existing) return existing
  const metaPath = join(dir, `agent-${id}.meta.json`)
  const agentMeta = existsSync(metaPath) ? JSON.parse(readFileSync(metaPath, "utf8")) : {}
  const lead: Lead = {
    id,
    label: agentMeta.description ?? id,
    phase: agentMeta.workflowPhase ?? "",
    cwd: "",
    remotes: new Set(),
    startedAt: null,
    lastAt: null,
    context: 0,
    contextSeries: [],
    output: 0,
    counts: {},
    busyMs: {},
    events: [],
    files: new Map(),
    note: "",
    prompt: "",
    workers: new Map(),
    activity: [],
    tools: new Map(),
    result: undefined,
    offset: 0,
  }
  leads.set(id, lead)
  return lead
}

const record = (lead: Lead, kind: Kind, text: string, at: string) => {
  const activity = { at, lead: lead.label.replace(/^lead:/, ""), kind, text }
  lead.activity.push(activity)
  if (lead.activity.length > KEEP) lead.activity.shift()
  lead.counts[kind] = (lead.counts[kind] ?? 0) + 1
  if (kind !== "finished") lead.events.push([Date.parse(at), kind])
  return activity
}

const ingest = (lead: Lead, line: Line) => {
  const at = line.timestamp ?? new Date().toISOString()
  lead.startedAt ??= at
  lead.lastAt = at
  lead.cwd ||= line.cwd ?? ""
  if (line.type === "user" && !lead.prompt) {
    const raw = line.message?.content
    lead.prompt = typeof raw === "string" ? raw : resultText(raw)
  }
  const content = Array.isArray(line.message?.content) ? line.message.content : []
  if (line.type === "assistant") {
    const usage = line.message?.usage
    if (usage) {
      lead.context = usage.input_tokens + usage.cache_read_input_tokens + usage.cache_creation_input_tokens
      lead.output += usage.output_tokens ?? 0
      if (lead.contextSeries.at(-1)?.[1] !== lead.context) lead.contextSeries.push([Date.parse(at), lead.context])
    }
    for (const block of content) {
      if (block.type === "text" && block.text.trim()) {
        lead.note = oneLine(block.text, 600)
        record(lead, "note", oneLine(block.text), at)
      }
      if (block.type !== "tool_use") continue
      const remote = block.name === "Bash" ? block.input.command?.match(SSH)?.[1] : undefined
      if (remote) lead.remotes.add(remote)
      const described = describeTool(block.name, block.input)
      if (!described) continue
      const [kind, text, command] = described
      record(lead, kind, text, at)
      lead.tools.set(block.id, { kind, text, command, at })
      if (kind === "wrote" || kind === "edited") {
        const key = shortPath(command, 4)
        lead.files.set(key, { n: (lead.files.get(key)?.n ?? 0) + 1, at, kind })
      }
      if (kind === "spawned") lead.workers.set(block.id, { id: block.id, description: text, status: "running", tokens: null })
    }
  }
  if (line.type === "user")
    for (const block of content) {
      if (block.type !== "tool_result") continue
      const text = resultText(block.content)
      const worker = lead.workers.get(block.tool_use_id)
      if (worker && !/Async agent launched/.test(text)) {
        worker.status = "done"
        worker.tokens = Number(text.match(/subagent_tokens:\s*(\d+)/)?.[1]) || null
      }
      const pending = lead.tools.get(block.tool_use_id)
      if (!pending) continue
      lead.busyMs[pending.kind] = (lead.busyMs[pending.kind] ?? 0) + Math.max(0, Date.parse(at) - Date.parse(pending.at))
      if (block.is_error) record(lead, "failed", pending.text, at)
      lead.tools.delete(block.tool_use_id)
    }
}

const refresh = () => {
  for (const file of readdirSync(dir)) {
    const id = file.match(/^agent-(\w+)\.jsonl$/)?.[1]
    if (!id) continue
    const lead = ensure(id)
    const read = readFrom<Line>(join(dir, file), lead.offset)
    lead.offset = read.offset
    for (const line of read.lines) ingest(lead, line)
  }
  const journal = readFrom<JournalEvent>(join(dir, "journal.jsonl"), journalOffset)
  journalOffset = journal.offset
  for (const event of journal.lines) {
    if (!event.agentId) continue
    const lead = ensure(event.agentId)
    if (event.type === "started") {
      lead.label = event.label ?? lead.label
      lead.phase = event.phase ?? lead.phase
    }
    if (event.type === "result") {
      lead.result = event.result
      record(lead, "finished", summarize(event.result), lead.lastAt ?? new Date().toISOString())
    }
  }
}

const readDecisions = () => (existsSync(DECISIONS) ? JSON.parse(readFileSync(DECISIONS, "utf8")) : { needsYou: [], decided: [] })

const status = (lead: Lead) =>
  lead.result !== undefined ? "finished" : lead.lastAt && Date.now() - Date.parse(lead.lastAt) > STALL_MS ? "stalled" : "running"

const spanOf = (lead: Lead, current: Set<Lead>) =>
  [Date.parse(lead.startedAt ?? ""), current.has(lead) && status(lead) === "running" ? Date.now() : Date.parse(lead.lastAt ?? "")] as const

const mergeSpans = (spans: (readonly [number, number])[]) =>
  [...spans]
    .sort((a, b) => a[0] - b[0])
    .reduce<[number, number][]>((merged, [start, end]) => {
      const last = merged.at(-1)
      if (last && start <= last[1] + GAP_MS) last[1] = Math.max(last[1], end)
      else merged.push([start, end])
      return merged
    }, [])

const downsample = <T>(points: T[], max: number) => {
  if (points.length <= max) return points
  const step = points.length / max
  return [...Array.from({ length: max - 1 }, (_, i) => points[Math.floor(i * step)]), points.at(-1) as T]
}

const commonPrefix = (a: string, b = "") => {
  let n = 0
  while (n < a.length && a[n] === b[n]) n++
  return n
}

const briefs = (prompts: string[]) => {
  const sorted = [...new Set(prompts)].sort()
  return new Map(
    sorted.map((prompt, i) => {
      const shared = Math.max(commonPrefix(prompt, sorted[i - 1]), commonPrefix(prompt, sorted[i + 1]))
      const start = prompt.lastIndexOf("\n", shared) + 1
      return [prompt, prompt.slice(start, start + BRIEF_CHARS).trim()]
    }),
  )
}

const projectOf = (cwd: string) => {
  const root = Bun.spawnSync(["git", "-C", cwd, "rev-parse", "--show-toplevel"]).stdout.toString().trim() || cwd
  return basename(root.replace(/\/\.claude\/worktrees\/.*$/, ""))
}

let project = process.env.PROJECT ?? ""

const pickCurrent = () => {
  const current = new Map<string, Lead>()
  for (const lead of leads.values()) {
    const previous = current.get(lead.label)
    const finishedWins = (lead.result !== undefined) !== (previous?.result !== undefined)
    if (!previous || (finishedWins ? lead.result !== undefined : (lead.startedAt ?? "") > (previous.startedAt ?? ""))) current.set(lead.label, lead)
  }
  return [...current.values()].sort((a, b) => (a.startedAt ?? "").localeCompare(b.startedAt ?? ""))
}

const state = () => {
  refresh()
  const list = pickCurrent()
  const current = new Set(list)
  const started = [...leads.values()].filter(l => l.startedAt && l.lastAt)
  const active = mergeSpans(started.map(l => spanOf(l, current)))
  const brief = briefs(list.map(l => l.prompt))
  const cwd = list.find(l => l.cwd)?.cwd
  if (!project && cwd) project = projectOf(cwd)
  const attemptOf = (l: Lead) => started.filter(o => o.label === l.label && (o.startedAt ?? "") <= (l.startedAt ?? "")).length
  const phases = (PHASES.length ? PHASES : [...new Set(list.map(l => l.phase))].map(title => ({ title, detail: "" }))).map(({ title, detail }) => {
    const inPhase = list.filter(l => l.phase === title)
    return { title, detail, total: inPhase.length, finished: inPhase.filter(l => status(l) === "finished").length }
  })
  return {
    title: TITLE,
    project,
    runId,
    now: Date.now(),
    startedAt: list[0]?.startedAt ?? null,
    activeMs: active.reduce((sum, [start, end]) => sum + end - start, 0),
    gaps: active.slice(1).map(([start], i) => [active[i][1], start]),
    decisions: readDecisions(),
    contextCap: CONTEXT_CAP,
    phases,
    attempts: started.map(l => ({
      attempt: attemptOf(l),
      id: l.id,
      name: l.label.replace(/^lead:/, ""),
      current: current.has(l),
      status: status(l),
      span: spanOf(l, current),
      events: l.events.filter(([, kind]) => kind !== "note"),
    })),
    leads: list.map(l => ({
      id: l.id,
      name: l.label.replace(/^lead:/, ""),
      phase: l.phase,
      remotes: [...l.remotes],
      status: status(l),
      startedAt: l.startedAt,
      lastAt: l.lastAt,
      context: l.context,
      contextSeries: downsample(l.contextSeries, SERIES_POINTS),
      output: l.output,
      counts: l.counts,
      busyMs: l.busyMs,
      files: [...l.files.entries()].sort((a, b) => b[1].at.localeCompare(a[1].at)).slice(0, 8).map(([path, f]) => ({ path, ...f })),
      note: l.note,
      brief: brief.get(l.prompt) ?? "",
      attempt: attemptOf(l),
      attempts: started.filter(o => o.label === l.label).length,
      span: spanOf(l, current),
      inflight: status(l) === "running" ? [...l.tools.values()] : [],
      recent: l.activity.filter(a => a.kind !== "finished").slice(-30).reverse(),
      workers: [...l.workers.values()],
      current: l.activity.findLast(a => a.kind !== "finished") ?? null,
      result: l.result ?? null,
    })),
    feed: list
      .flatMap(l => l.activity)
      .sort((a, b) => b.at.localeCompare(a.at))
      .slice(0, 80),
  }
}

const fetch = (req: Request) => {
  const path = new URL(req.url).pathname
  if (path === "/api/state") return Response.json(state())
  if (path === "/api/script") return script ? new Response(script) : new Response("no script", { status: 404 })
  return new Response(Bun.file(join(import.meta.dir, "index.html")))
}

const serve = (port: number): ReturnType<typeof Bun.serve> => {
  try {
    return Bun.serve({ hostname: HOST, port, fetch })
  } catch (error) {
    if (!(error instanceof Error && "code" in error && error.code === "EADDRINUSE")) throw error
    return serve(port + 1)
  }
}

const server = serve(Number(process.env.PORT ?? 4777))
console.log(`${TITLE}: ${server.url} watching ${dir}`)
