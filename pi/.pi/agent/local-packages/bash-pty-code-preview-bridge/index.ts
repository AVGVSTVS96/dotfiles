/**
 * bash-pty-code-preview-bridge
 *
 * Local compatibility bridge for pi-bash-live-view + pi-code-previews.
 *
 * Pi currently treats `bash` as one tool registration, so if pi-bash-live-view owns
 * `bash` for `usePTY` execution, pi-code-previews skips bash result styling. This
 * bridge registers one composed `bash` tool that uses:
 *
 * - pi-bash-live-view internals for `usePTY: true` PTY execution/live widget
 * - pi-code-previews' bash-specific renderer for styled bash call/result output
 * - Pi's built-in bash execution for normal non-PTY bash calls
 *
 * If the bash-specific renderer moves after an update, the bridge falls back to
 * pi-code-previews' public shell wrapper instead of preventing Pi from starting.
 *
 *
 * IMPORTANT: Pi uses first-registration-wins for tools. Keep this local package
 * first in ~/.pi/agent/settings.json `packages`, before npm:pi-bash-live-view and
 * before any other extension that registers `bash`.
 *
 * See README.md in this directory for verification/update instructions.
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { createBashToolDefinition } from "@earendil-works/pi-coding-agent";

const PI_NODE_MODULES =
  "/Users/bassimshahidy/.local/share/fnm/node-versions/v25.6.1/installation/lib/node_modules";
const PI_CODE_PREVIEWS_ROOT = `${PI_NODE_MODULES}/pi-code-previews`;
const PI_BASH_LIVE_VIEW_ROOT = `${PI_NODE_MODULES}/pi-bash-live-view`;

const bashLiveViewParams = {
  type: "object",
  required: ["command"],
  properties: {
    command: { type: "string", description: "Command to execute" },
    timeout: { type: "number", description: "Timeout in seconds" },
    usePTY: {
      type: "boolean",
      description:
        "Run inside a PTY with a live terminal widget. Use for terminal-style programs and rich progress UIs.",
    },
  },
};

type BashLiveViewInternals = {
  executePtyCommand: (
    toolCallId: string,
    params: { command: string; timeout?: number },
    signal: AbortSignal,
    ctx: any,
  ) => Promise<any>;
  ensureSpawnHelperExecutable?: () => void;
};

type CodePreviewPublicApi = {
  loadCodePreviewSettings?: (projectCwd?: string) => Promise<any>;
  withCodePreviewShell?: (tool: any, options?: any) => any;
};

type CodePreviewPrivateApi = {
  registerBash?: (pi: ExtensionAPI, cwd: string, options?: any) => void;
};

async function importFirst<T extends Record<string, any>>(
  label: string,
  paths: string[],
): Promise<T | undefined> {
  const errors: string[] = [];
  for (const path of paths) {
    try {
      return (await import(path)) as T;
    } catch (error) {
      errors.push(`${path}: ${error instanceof Error ? error.message : String(error)}`);
    }
  }
  console.warn(`[bash-pty-code-preview-bridge] Could not load ${label}.\n${errors.join("\n")}`);
  return undefined;
}

let bashLiveViewInternals: Promise<BashLiveViewInternals | undefined> | undefined;

function loadBashLiveViewInternals(): Promise<BashLiveViewInternals | undefined> {
  bashLiveViewInternals ??= (async () => {
    const [ptyModule, spawnHelperModule] = await Promise.all([
      importFirst<{ executePtyCommand?: BashLiveViewInternals["executePtyCommand"] }>(
        "pi-bash-live-view PTY executor",
        [`${PI_BASH_LIVE_VIEW_ROOT}/pty-execute.ts`],
      ),
      importFirst<{ ensureSpawnHelperExecutable?: () => void }>(
        "pi-bash-live-view spawn helper",
        [`${PI_BASH_LIVE_VIEW_ROOT}/spawn-helper.ts`],
      ),
    ]);

    if (!ptyModule?.executePtyCommand) return undefined;
    return {
      executePtyCommand: ptyModule.executePtyCommand,
      ensureSpawnHelperExecutable: spawnHelperModule?.ensureSpawnHelperExecutable,
    };
  })();
  return bashLiveViewInternals;
}

async function loadCodePreviewPublicApi(cwd: string): Promise<CodePreviewPublicApi | undefined> {
  const api = await importFirst<CodePreviewPublicApi>("pi-code-previews public API", [
    `${PI_CODE_PREVIEWS_ROOT}/dist/index.js`,
  ]);
  await api?.loadCodePreviewSettings?.(cwd);
  return api;
}

async function loadCodePreviewPrivateApi(cwd: string): Promise<CodePreviewPrivateApi | undefined> {
  await loadCodePreviewPublicApi(cwd);
  const bashModule = await importFirst<{ registerBash?: CodePreviewPrivateApi["registerBash"] }>(
    "pi-code-previews bash renderer",
    [`${PI_CODE_PREVIEWS_ROOT}/src/tool-renderers/bash.ts`],
  );

  if (!bashModule?.registerBash) return undefined;

  return {
    registerBash: bashModule.registerBash,
  };
}

async function makeCodePreviewBashTool(cwd: string): Promise<any | undefined> {
  const privateApi = await loadCodePreviewPrivateApi(cwd);
  if (!privateApi?.registerBash) return undefined;

  let captured: any;

  // Reuse pi-code-previews' own bash renderer without letting it register globally.
  // This is the key: we capture its rendered tool definition, then graft our PTY execute onto it.
  privateApi.registerBash(
    {
      registerTool(tool: any) {
        captured = tool;
      },
    } as unknown as ExtensionAPI,
    cwd,
  );

  if (!captured) return undefined;
  return captured;
}

async function addCodePreviewShellFallback(tool: any, cwd: string): Promise<any> {
  const publicApi = await loadCodePreviewPublicApi(cwd);
  if (!publicApi?.withCodePreviewShell) return tool;
  return publicApi.withCodePreviewShell(tool, { preserveSelfShell: false });
}

export default async function bashPtyCodePreviewBridge(pi: ExtensionAPI) {
  void loadBashLiveViewInternals().then((internals) =>
    internals?.ensureSpawnHelperExecutable?.(),
  );

  pi.on("session_start", async (_event, ctx) => {
    const cwd = ctx.cwd;
    const baseBash = createBashToolDefinition(cwd);
    const styledBash = await makeCodePreviewBashTool(cwd);

    const composedBash = {
      ...styledBash,
      ...(!styledBash ? baseBash : undefined),
      name: "bash",
      label: "bash",
      description: `${baseBash.description} Supports optional usePTY=true live terminal rendering for terminal-style programs and richer progress UIs.`,
      parameters: bashLiveViewParams,
      async execute(toolCallId: string, params: any, signal: AbortSignal | undefined, onUpdate: any, execCtx: any) {
        if (params.usePTY === true) {
          const internals = await loadBashLiveViewInternals();
          if (!internals?.executePtyCommand) {
            throw new Error("pi-bash-live-view PTY executor is unavailable after package update.");
          }
          internals.ensureSpawnHelperExecutable?.();
          return internals.executePtyCommand(
            toolCallId,
            params,
            signal ?? new AbortController().signal,
            execCtx,
          );
        }
        return baseBash.execute(toolCallId, params, signal, onUpdate, execCtx);
      },
    };

    pi.registerTool(styledBash ? composedBash : await addCodePreviewShellFallback(composedBash, cwd));
  });
}
