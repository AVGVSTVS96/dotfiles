---
name: setup
description: Setup and configure assistant-ui in a project. Use when installing packages, configuring runtimes, setting up chat UI, or troubleshooting setup issues.
version: 0.3.0
license: MIT
---

# assistant-ui Setup

## CLI Commands

### Quick Decision Flow

- Existing Next.js app (`package.json` exists): use `npx assistant-ui@latest init`
- Existing app in CI/agent/non-interactive shell: use `npx assistant-ui@latest init --yes`
- Existing app + force overwrite of conflicts: add `--overwrite`
- New app / empty directory: use `npx assistant-ui@latest create <name>`
- Need specific starter template: add `-t <default|minimal|cloud|langgraph|mcp>`
- Need a curated example: use `npx assistant-ui@latest create <name> --example <example>`

### New Project (`create`)

```bash
npx assistant-ui@latest create my-app          # interactive template picker
npx assistant-ui@latest create my-app -t cloud  # skip picker, use cloud template
```

Templates: `default`, `minimal`, `cloud`, `langgraph`, `mcp`

When no `-t` flag is passed, an interactive template picker is shown. In non-interactive shells, defaults to `default`.

### Existing Next.js Project (`init`)

```bash
npx assistant-ui@latest init --yes
```

The `init` command is for **existing projects only** (requires `package.json`). If no project is found, it automatically forwards to `create`.

The `--yes` flag runs non-interactively (no prompts).

### Add Registry Components

```bash
npx assistant-ui@latest add markdown-text
npx assistant-ui@latest add thread-list
```

Registry: `https://r.assistant-ui.com/{name}.json`

---

## What `init` Creates

The CLI scaffolds a complete working chat UI:

- `components/assistant-ui/` — thread, attachment, markdown-text, tool-fallback, tooltip-icon-button
- `components/ui/` — avatar, button, collapsible, dialog, tooltip (includes TooltipProvider)
- `app/api/chat/route.ts` — AI SDK streaming endpoint (openai, streamText, convertToModelMessages)
- `app/assistant.tsx` — runtime provider (useChatRuntime + AssistantChatTransport)
- `lib/utils.ts` — `cn()` utility (clsx + tailwind-merge)
- `components.json` — shadcn config

The generated code uses Tailwind CSS v4 and builds clean out of the box.

---

## Template Code Policy

When using CLI templates (`npx assistant-ui create`), **never modify the generated code** unless the user explicitly asks. Templates use intentional, tested configurations including specific model names, `providerOptions`, and streaming settings.

---

## Non-Default Setups

For runtimes other than AI SDK or frameworks other than Next.js, consult the reference files:

| Setup | Runtime Hook | Reference |
|-------|-------------|-----------|
| AI SDK advanced (tools, cloud, options) | `useChatRuntime` | [references/ai-sdk.md](./references/ai-sdk.md) |
| LangGraph agents | `useLangGraphRuntime` | [references/langgraph.md](./references/langgraph.md) |
| AG-UI protocol | `useAgUiRuntime` | [references/ag-ui.md](./references/ag-ui.md) |
| A2A protocol | `useA2ARuntime` | [references/a2a.md](./references/a2a.md) |
| Custom streaming API | `useLocalRuntime` | [references/custom-backend.md](./references/custom-backend.md) |
| Existing state (Redux/Zustand) | `useExternalStoreRuntime` | [references/custom-backend.md](./references/custom-backend.md) |
| Vite / TanStack Start | — | [references/tanstack.md](./references/tanstack.md) |

---

## Deprecated Packages

NEVER install `@assistant-ui/styles` or `@assistant-ui/react-ui` — both are deprecated and deleted.

---

## Troubleshooting

For issues not covered by the reference files, use the docs website:

1. **Fetch the index**: `https://www.assistant-ui.com/llms.txt` — compact table of contents
2. **Fetch specific pages**: Append `.mdx` to the docs URL, e.g. `https://www.assistant-ui.com/docs/runtimes/ai-sdk.mdx`
