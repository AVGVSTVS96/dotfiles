/**
 * pi-note — v1.5
 *
 * Pins a single note above the input editor, scoped to the current session.
 *
 * Commands:
 *   /note <content>             Set/replace the session note (default prefix "note").
 *   /note :recap: <content>     Set a note with a custom prefix word.
 *   /note                       Open a multi-line editor to compose/edit the note.
 *   /notes                      Browse notes; pick one to open it in the editor and
 *                               restore it. Cycle scope (this session / this project /
 *                               all projects) by selecting the top “Scope:…” row.
 *   /note-clear                 Clear the note in this session only.
 *
 * The note is stored via pi.appendEntry, so it never enters the LLM context.
 * The PINNED note is SESSION-scoped: reconstruction scans all entries of the
 * current session (not just the active /tree branch), so switching branches can
 * never strand or lose a note. /notes can additionally browse OTHER sessions by
 * reading their .jsonl files (enumerated via SessionManager.list / listAll).
 *
 * Visual style:
 *   ※ note: long content that wraps across multiple
 *     lines with a 2-space hanging indent
 */

import type { ExtensionAPI, ExtensionContext, Theme } from "@earendil-works/pi-coding-agent";
import { SessionManager } from "@earendil-works/pi-coding-agent";
import type { Component } from "@earendil-works/pi-tui";
import { visibleWidth } from "@earendil-works/pi-tui";
import { readFileSync } from "node:fs";

// ----- types ---------------------------------------------------------------

type NoteEntryData = { text: string; prefix: string; createdAt: number } | { deleted: true };

type Note = { text: string; prefix: string };

// ----- constants -----------------------------------------------------------

const WIDGET_KEY = "pi-note";
const ENTRY_TYPE = "note";
const DEFAULT_PREFIX = "note";
const ICON = "※";
// Continuation indent matches the visible width of "※ " so wrapped lines
// align under the start of the prefix word.
const CONT_INDENT = "  ";

// ----- parsing -------------------------------------------------------------

/**
 * Parse the raw `/note` argument string.
 *
 *   ":recap: we picked postgres" → { prefix: "recap", text: "we picked postgres" }
 *   "remember to bump changeset" → { prefix: "note",  text: "remember to bump changeset" }
 *
 * Returns null if there is no usable content.
 */
function parseArgs(raw: string): { prefix: string; text: string } | null {
  const trimmed = raw.trim();
  if (trimmed === "") return null;

  // `:word: <content>` — word has no whitespace and no inner colons.
  // Content must contain at least one non-whitespace character.
  const match = trimmed.match(/^:([^\s:]+):\s+([\s\S]*\S)\s*$/);
  if (match) {
    return { prefix: match[1]!, text: match[2]! };
  }
  return { prefix: DEFAULT_PREFIX, text: trimmed };
}

// ----- word-wrap -----------------------------------------------------------

/**
 * Word-wrap one logical paragraph. The first line may have a different
 * available width than continuation lines (because the icon + prefix only
 * appears on the first line).
 */
function wrapParagraph(text: string, firstWidth: number, contWidth: number): string[] {
  const safeFirst = Math.max(1, firstWidth);
  const safeCont = Math.max(1, contWidth);

  const words = text.split(/\s+/).filter((w) => w.length > 0);
  if (words.length === 0) return [""];

  const lines: string[] = [];
  let current = "";
  let available = safeFirst;

  const flush = () => {
    lines.push(current);
    current = "";
    available = safeCont;
  };

  const hardBreakWord = (word: string): string => {
    // Split a single word that is wider than `available` into chunks
    // that fit. Returns the unconsumed tail (always fits in `available`).
    let remaining = word;
    while (visibleWidth(remaining) > available) {
      let take = "";
      for (const ch of remaining) {
        if (visibleWidth(take + ch) > available) break;
        take += ch;
      }
      if (take === "") {
        // Safety: a single character wider than the line; give up
        // and emit it on its own line to avoid an infinite loop.
        lines.push(remaining[0] ?? "");
        remaining = remaining.slice(1);
        available = safeCont;
        continue;
      }
      lines.push(take);
      remaining = remaining.slice(take.length);
      available = safeCont;
    }
    return remaining;
  };

  for (const word of words) {
    if (visibleWidth(word) > available && current === "") {
      current = hardBreakWord(word);
      continue;
    }

    const candidate = current === "" ? word : `${current} ${word}`;
    if (visibleWidth(candidate) <= available) {
      current = candidate;
    } else {
      flush();
      if (visibleWidth(word) > available) {
        current = hardBreakWord(word);
      } else {
        current = word;
      }
    }
  }
  if (current !== "") lines.push(current);
  return lines;
}

// ----- rendering -----------------------------------------------------------

class NoteShelf implements Component {
  private cachedWidth?: number;
  private cachedLines?: string[];

  constructor(
    private readonly prefix: string,
    private readonly text: string,
    private readonly theme: Theme,
  ) {}

  render(width: number): string[] {
    if (this.cachedLines && this.cachedWidth === width) {
      return this.cachedLines;
    }

    const th = this.theme;
    const headWidth = visibleWidth(`${ICON} ${this.prefix}: `);
    const firstAvail = Math.max(1, width - headWidth);
    const contAvail = Math.max(1, width - CONT_INDENT.length);

    // Preserve user-supplied newlines as paragraph breaks.
    const paragraphs = this.text.split("\n");
    const lines: string[] = [];

    for (let i = 0; i < paragraphs.length; i++) {
      const isFirstParagraph = i === 0;
      const wrapped = wrapParagraph(
        paragraphs[i] ?? "",
        isFirstParagraph ? firstAvail : contAvail,
        contAvail,
      );
      for (let j = 0; j < wrapped.length; j++) {
        const raw = wrapped[j] ?? "";
        if (isFirstParagraph && j === 0) {
          // First line: ※  +  bold "<prefix>:"  +  text
          // Everything is dim grey; only the prefix word is also bold.
          const styled =
            th.fg("dim", `${ICON} `) +
            th.fg("dim", th.bold(`${this.prefix}:`)) +
            th.fg("dim", ` ${raw}`);
          lines.push(styled);
        } else {
          lines.push(th.fg("dim", `${CONT_INDENT}${raw}`));
        }
      }
    }

    this.cachedWidth = width;
    this.cachedLines = lines;
    return lines;
  }

  invalidate(): void {
    this.cachedWidth = undefined;
    this.cachedLines = undefined;
  }
}

// ----- extension -----------------------------------------------------------

export default function (pi: ExtensionAPI) {
  // In-memory state. Reconstructed from session entries on every
  // session_start and session_tree event.
  let currentNote: Note | null = null;
  // Last scope used by /notes; persists across invocations within this session.
  let notesScope: Scope = "session";

  function reconstruct(ctx: ExtensionContext): void {
    currentNote = null;
    for (const entry of ctx.sessionManager.getEntries()) {
      if (entry.type !== "custom" || entry.customType !== ENTRY_TYPE) continue;
      const data = entry.data as NoteEntryData | undefined;
      if (!data) continue;
      if ("deleted" in data && data.deleted) currentNote = null;
      else if ("text" in data) currentNote = { text: data.text, prefix: data.prefix };
    }
  }

  // A note plus the session it came from. `fromCurrentSession` drives labeling
  // and lets the editor know it's restoring across sessions.
  type SavedNote = {
    text: string;
    prefix: string;
    createdAt: number;
    sessionId?: string;
    sessionName?: string;
    fromCurrentSession: boolean;
  };

  type Scope = "session" | "project" | "global";
  const SCOPE_LABEL: Record<Scope, string> = {
    session: "This session",
    project: "This project",
    global: "All projects",
  };
  const nextScope = (s: Scope): Scope =>
    s === "session" ? "project" : s === "project" ? "global" : "session";

  // Extract non-deleted note entries from a raw list of session entries.
  function notesFromEntries(
    entries: readonly { type: string; customType?: string; data?: unknown }[],
    meta: {
      fromCurrentSession: boolean;
      sessionId?: string;
      sessionName?: string;
    },
  ): SavedNote[] {
    const out: SavedNote[] = [];
    for (const entry of entries) {
      if (entry.type !== "custom" || entry.customType !== ENTRY_TYPE) continue;
      const data = entry.data as NoteEntryData | undefined;
      if (!data || "deleted" in data || !("text" in data)) continue;
      out.push({
        text: data.text,
        prefix: data.prefix,
        createdAt: data.createdAt,
        ...meta,
      });
    }
    return out;
  }

  // Gather notes for the requested scope, newest first.
  //  - session: in-memory entries of the current session (always current,
  //    works for unsaved/in-memory sessions too).
  //  - project/global: enumerate session files via SessionManager.list/listAll,
  //    then raw-read each file's note lines (string pre-filter before JSON.parse
  //    keeps it fast on large sessions).
  async function gatherNotes(ctx: ExtensionContext, scope: Scope): Promise<SavedNote[]> {
    if (scope === "session") {
      const notes = notesFromEntries(ctx.sessionManager.getEntries(), {
        fromCurrentSession: true,
        sessionId: ctx.sessionManager.getSessionId(),
      });
      return notes.reverse();
    }

    const infos =
      scope === "project" ? await SessionManager.list(ctx.cwd) : await SessionManager.listAll();
    const currentFile = ctx.sessionManager.getSessionFile();
    const out: SavedNote[] = [];
    for (const info of infos) {
      let raw: string;
      try {
        raw = readFileSync(info.path, "utf8");
      } catch {
        continue;
      }
      const lines: { type: string; customType?: string; data?: unknown }[] = [];
      for (const line of raw.split("\n")) {
        if (!line.includes('"customType":"note"')) continue;
        try {
          lines.push(JSON.parse(line));
        } catch {
          /* skip malformed line */
        }
      }
      out.push(
        ...notesFromEntries(lines, {
          fromCurrentSession: info.path === currentFile,
          sessionId: info.id,
          sessionName: info.name,
        }),
      );
    }
    out.sort((a, b) => (b.createdAt ?? 0) - (a.createdAt ?? 0));
    return out;
  }

  /** One-line label for the /notes selector: "[prefix] <when> · first line… ← src". */
  function formatNoteLabel(n: SavedNote, scope: Scope): string {
    const time = n.createdAt
      ? new Date(n.createdAt).toLocaleString([], {
          month: "short",
          day: "numeric",
          hour: "2-digit",
          minute: "2-digit",
        })
      : "";
    const firstLine = n.text.split("\n")[0] ?? "";
    const snippet = firstLine.length > 56 ? `${firstLine.slice(0, 53)}…` : firstLine;
    let src = "";
    if (scope !== "session") {
      src = n.fromCurrentSession
        ? "  ← this session"
        : `  ← ${n.sessionName ?? n.sessionId?.slice(0, 8) ?? "?"}`;
    }
    return `[${n.prefix}]${time ? ` ${time}` : ""} · ${snippet}${src}`;
  }

  /** Persist a note and refresh the pinned shelf. */
  function setNote(ctx: ExtensionContext, text: string, prefix: string): void {
    pi.appendEntry(ENTRY_TYPE, {
      text,
      prefix,
      createdAt: Date.now(),
    } as NoteEntryData);
    currentNote = { text, prefix };
    renderShelf(ctx);
  }

  // Open the multi-line editor to compose or edit a note. `base` seeds the
  // editor text + prefix (null = brand-new note with the default prefix).
  // On submit, the edited body becomes the note; the prefix is preserved.
  async function composeInEditor(ctx: ExtensionContext, base: Note | null): Promise<void> {
    if (!ctx.hasUI) {
      ctx.ui.notify("Usage: /note [:prefix:] <content>", "warning");
      return;
    }
    const prefix = base?.prefix ?? DEFAULT_PREFIX;
    const title = `${base ? "Edit" : "New"} note (:${prefix}:) — Enter submit, Shift+Enter newline, Esc cancel`;
    const result = await ctx.ui.editor(title, base?.text ?? "");
    if (result === undefined) {
      ctx.ui.notify("Note unchanged", "info");
      return;
    }
    const text = result.trim();
    if (text === "") {
      ctx.ui.notify("Note content required", "warning");
      return;
    }
    setNote(ctx, text, prefix);
  }

  function renderShelf(ctx: ExtensionContext): void {
    if (!ctx.hasUI) return;
    if (currentNote === null) {
      ctx.ui.setWidget(WIDGET_KEY, undefined);
      return;
    }
    const { prefix, text } = currentNote;
    ctx.ui.setWidget(WIDGET_KEY, (_tui, theme) => new NoteShelf(prefix, text, theme), {
      placement: "aboveEditor",
    });
  }

  pi.on("session_start", async (_event, ctx) => {
    reconstruct(ctx);
    renderShelf(ctx);
  });

  pi.on("session_tree", async (_event, ctx) => {
    reconstruct(ctx);
    renderShelf(ctx);
  });

  pi.registerCommand("note", {
    description: "Pin a note above the input. Usage: /note [:prefix:] <content>",
    handler: async (args, ctx) => {
      const trimmed = (args ?? "").trim();

      // Bare `/note` → open the multi-line editor (edit current note if any,
      // otherwise compose a fresh one).
      if (trimmed === "") {
        await composeInEditor(ctx, currentNote);
        return;
      }

      // `/note [:prefix:] <content>` → set directly, no editor.
      const parsed = parseArgs(trimmed);
      if (parsed === null) {
        ctx.ui.notify("Note content required", "warning");
        return;
      }
      setNote(ctx, parsed.text, parsed.prefix);
    },
  });

  pi.registerCommand("notes", {
    description: "Browse/restore notes. Toggle scope: session / project / all.",
    handler: async (_args, ctx) => {
      if (!ctx.hasUI) {
        const notes = await gatherNotes(ctx, "session");
        if (notes.length === 0) {
          ctx.ui.notify("No notes saved in this session", "info");
          return;
        }
        const latest = notes[0]!;
        ctx.ui.notify(`${notes.length} note(s). Latest (${latest.prefix}): ${latest.text}`, "info");
        return;
      }

      // notesScope persists for the rest of this session (declared in closure).
      while (true) {
        const notes = await gatherNotes(ctx, notesScope);
        const toggleRow = `↹ Scope: ${SCOPE_LABEL[notesScope]} — select to cycle`;
        // Index-prefixed labels keep options unique so we can map the chosen
        // string back to its note even if two notes share a snippet.
        const noteLabels = notes.map((n, i) => `${i + 1}. ${formatNoteLabel(n, notesScope)}`);
        const title =
          notes.length === 0
            ? `Notes (${SCOPE_LABEL[notesScope]}) — none found`
            : `Notes (${SCOPE_LABEL[notesScope]})`;
        const choice = await ctx.ui.select(title, [toggleRow, ...noteLabels]);
        if (choice === undefined) return;
        if (choice === toggleRow) {
          notesScope = nextScope(notesScope);
          continue;
        }
        const idx = noteLabels.indexOf(choice);
        if (idx < 0) return;
        // Restores into the CURRENT session (setNote appends here), preserving
        // the chosen note's prefix — even when it came from another session.
        await composeInEditor(ctx, notes[idx]!);
        return;
      }
    },
  });

  pi.registerCommand("note-clear", {
    description: "Clear the note pinned above the input in this session.",
    handler: async (_args, ctx) => {
      if (currentNote === null) {
        ctx.ui.notify("No note to clear", "info");
        return;
      }
      pi.appendEntry(ENTRY_TYPE, { deleted: true } as NoteEntryData);
      currentNote = null;
      renderShelf(ctx);
    },
  });
}
