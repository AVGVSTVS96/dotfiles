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
 * - pi-code-previews internals for styled bash call/result rendering
 * - Pi's built-in bash execution for normal non-PTY bash calls
 *
 * IMPORTANT: Pi uses first-registration-wins for tools. Keep this local package
 * first in ~/.pi/agent/settings.json `packages`, before npm:pi-bash-live-view and
 * before any other extension that registers `bash`.
 *
 * See README.md in this directory for verification/update instructions.
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { createBashToolDefinition } from "@earendil-works/pi-coding-agent";
import { Type } from "/Users/bassimshahidy/.local/share/fnm/node-versions/v25.6.1/installation/lib/node_modules/pi-bash-live-view/node_modules/@sinclair/typebox/build/esm/index.mjs";
import { executePtyCommand } from "/Users/bassimshahidy/.local/share/fnm/node-versions/v25.6.1/installation/lib/node_modules/pi-bash-live-view/pty-execute.ts";
import { ensureSpawnHelperExecutable } from "/Users/bassimshahidy/.local/share/fnm/node-versions/v25.6.1/installation/lib/node_modules/pi-bash-live-view/spawn-helper.ts";
import { registerBash as captureCodePreviewBash } from "/Users/bassimshahidy/.local/share/fnm/node-versions/v25.6.1/installation/lib/node_modules/pi-code-previews/src/tool-renderers/bash.ts";
import { initializeShiki } from "/Users/bassimshahidy/.local/share/fnm/node-versions/v25.6.1/installation/lib/node_modules/pi-code-previews/src/syntax/shiki.ts";
import { codePreviewSettings } from "/Users/bassimshahidy/.local/share/fnm/node-versions/v25.6.1/installation/lib/node_modules/pi-code-previews/src/settings/index.ts";
import { loadCodePreviewSettings } from "/Users/bassimshahidy/.local/share/fnm/node-versions/v25.6.1/installation/lib/node_modules/pi-code-previews/src/settings/bootstrap.ts";

const bashLiveViewParams = Type.Object({
  command: Type.String({ description: "Command to execute" }),
  timeout: Type.Optional(Type.Number({ description: "Timeout in seconds" })),
  usePTY: Type.Optional(
    Type.Boolean({
      description:
        "Run inside a PTY with a live terminal widget. Use for terminal-style programs and rich progress UIs.",
    }),
  ),
});

function makeCodePreviewBashTool(cwd: string): any {
  let captured: any;

  // Reuse pi-code-previews' own bash renderer without letting it register globally.
  // This is the key: we capture its rendered tool definition, then graft our PTY execute onto it.
  captureCodePreviewBash(
    {
      registerTool(tool: any) {
        captured = tool;
      },
    } as unknown as ExtensionAPI,
    cwd,
  );

  if (!captured) throw new Error("Failed to capture pi-code-previews bash renderer");
  return captured;
}

export default async function bashPtyCodePreviewBridge(pi: ExtensionAPI) {
  ensureSpawnHelperExecutable();
  await loadCodePreviewSettings();
  if (codePreviewSettings.syntaxHighlighting) void initializeShiki(codePreviewSettings.shikiTheme);

  pi.on("session_start", (_event, ctx) => {
    const cwd = ctx.cwd;
    const baseBash = createBashToolDefinition(cwd);
    const styledBash = makeCodePreviewBashTool(cwd);

    pi.registerTool({
      ...styledBash,
      name: "bash",
      label: "bash",
      description: `${baseBash.description} Supports optional usePTY=true live terminal rendering for terminal-style programs and richer progress UIs.`,
      parameters: bashLiveViewParams,
      async execute(toolCallId: string, params: any, signal: AbortSignal | undefined, onUpdate: any, execCtx: any) {
        if (params.usePTY === true) {
          return executePtyCommand(toolCallId, params, signal ?? new AbortController().signal, execCtx);
        }
        return baseBash.execute(toolCallId, params, signal, onUpdate, execCtx);
      },
    });
  });
}
