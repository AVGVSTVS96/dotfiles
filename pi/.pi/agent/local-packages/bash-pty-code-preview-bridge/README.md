# bash-pty-code-preview-bridge

Local Pi extension that composes two separate `bash` tool enhancements:

- [`pi-bash-live-view`](https://www.npmjs.com/package/pi-bash-live-view): adds `usePTY: true` and shows a live terminal widget while a bash command runs.
- [`pi-code-previews`](https://www.npmjs.com/package/pi-code-previews): adds styled/syntax-highlighted bash call and result rendering.

## Problem this solves

Pi currently treats `bash` as a single tool registration. Both extensions want to affect `bash`, but they affect different concerns:

| Extension | Wants to own |
| --- | --- |
| `pi-bash-live-view` | parameter schema + execution |
| `pi-code-previews` | `renderCall` + `renderResult` + shell styling |

Without this bridge, `pi-bash-live-view` owns `bash`, so `pi-code-previews` detects a conflict and skips bash styling. The result is:

1. `usePTY: true` correctly shows a live terminal while the command runs.
2. After the command completes, Pi shows the captured bash output using the plain fallback renderer.

This bridge registers one composed `bash` tool that combines both behaviors.

## How it works

The bridge is the active `bash` tool.

It imports the PTY execution implementation from `pi-bash-live-view`:

```ts
executePtyCommand(...)
```

It also captures `pi-code-previews`' own bash renderer by calling its internal `registerBash` function with a fake `pi` object:

```ts
captureCodePreviewBash({
  registerTool(tool) {
    captured = tool;
  },
}, cwd);
```

Then it registers a final composed tool:

```ts
pi.registerTool({
  ...styledBash,
  parameters: bashLiveViewParams,
  execute(...) {
    if (params.usePTY) return executePtyCommand(...);
    return baseBash.execute(...);
  },
});
```

So the behavior is:

```text
normal bash call
→ built-in bash executor
→ pi-code-previews styled renderer

bash call with usePTY=true
→ pi-bash-live-view PTY executor/live widget
→ pi-code-previews styled renderer
```

## Required package order

Pi uses **first registration wins** for tools. That means this bridge must load before `pi-bash-live-view` and before any other extension that registers `bash`.

The bridge should be first in `~/.pi/agent/settings.json`:

```json
{
  "packages": [
    "~/.pi/agent/local-packages/bash-pty-code-preview-bridge",
    "npm:pi-code-previews",
    "npm:@ifi/oh-pi-themes",
    "npm:pi-bash-live-view",
    "npm:@grayolson/pi-treebase",
    "npm:pi-research"
  ]
}
```

`pi-bash-live-view` and `pi-code-previews` should remain in the package list so `pi update` continues to update both packages. The bridge only composes their behavior.

## How to verify it works

After editing settings or updating packages, run:

```text
/reload
```

Then ask the agent to run a bash tool call with PTY enabled, for example:

```json
{
  "command": "for i in $(seq 1 10); do echo tick $i; sleep 0.25; done",
  "usePTY": true,
  "timeout": 5
}
```

Expected behavior:

1. A live terminal widget appears while the command is running.
2. After completion, the final bash output is displayed with `pi-code-previews` bash-specific styling instead of plain fallback output.

If live terminal works but final output is unstyled, the bridge probably did not win the `bash` registration. Check package order and ensure this bridge is first.

## Update compatibility

By default, this bridge tries to use the bash-specific `pi-code-previews` renderer so completed bash output keeps the nice styled block. If that renderer moves after a package update, the bridge falls back to the public `pi-code-previews` shell wrapper instead of preventing Pi from starting.

The bash-specific renderer path may need updating after package upgrades because it probes this non-public file:

```text
pi-code-previews/src/tool-renderers/bash.ts
```

The PTY execution path still depends on these `pi-bash-live-view` internals, but they are lazy-loaded so a future move should produce a `usePTY=true` error rather than preventing Pi from starting:

```text
pi-bash-live-view/pty-execute.ts
pi-bash-live-view/spawn-helper.ts
```

If `/reload` reports extension load errors after `pi update`, inspect those paths and adjust `index.ts`.

## Why not remove `pi-bash-live-view` from packages?

Do not remove it unless you are okay with it no longer being managed by Pi.

The bridge imports its implementation from the installed package. Keeping `npm:pi-bash-live-view` in settings ensures `pi update` updates it.

## Long-term fix

This bridge is a local workaround. The better long-term fix is for Pi core to support composable tool facets, for example:

- renderer-only registration for `renderCall` / `renderResult`
- execution middleware for wrapping tool execution
- parameter/schema extension for additive arguments such as `usePTY`

Then `pi-bash-live-view` could own execution only, `pi-code-previews` could own rendering only, and this bridge would no longer be needed.
