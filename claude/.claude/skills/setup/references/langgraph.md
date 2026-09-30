# LangGraph Integration

## Critical: Command Forwarding

When using LangGraph interrupts (human-in-the-loop), always forward `config.command`:

```tsx
stream: async function* (messages, config) {
  yield* sendMessage({
    threadId,
    messages,
    command: config.command,  // REQUIRED for interrupt resumption
  });
}
```

Without `config.command`, resuming from an interrupt causes Python error: `NoneType in _control_branch`.

---

## Basic Setup

```tsx
import { AssistantRuntimeProvider } from "@assistant-ui/react";
import { useLangGraphRuntime } from "@assistant-ui/react-langgraph";
import { Thread } from "@/components/assistant-ui/thread";

function Chat() {
  const runtime = useLangGraphRuntime({
    stream: async function* (messages, config) {
      const response = await fetch("/api/langgraph", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ messages, command: config.command }),
      });

      const reader = response.body?.getReader();
      const decoder = new TextDecoder();

      // parseLangGraphEvents is app-specific parser logic for your stream format.
      while (reader) {
        const { done, value } = await reader.read();
        if (done) break;
        for (const event of parseLangGraphEvents(decoder.decode(value))) {
          yield event;
        }
      }
    },
  });

  return (
    <AssistantRuntimeProvider runtime={runtime}>
      <Thread />
    </AssistantRuntimeProvider>
  );
}
```

---

## Complete Setup with Persistence

```tsx
import { Client } from "@langchain/langgraph-sdk";
import { useLangGraphRuntime } from "@assistant-ui/react-langgraph";
import { Thread } from "@/components/assistant-ui/thread";

const client = new Client({
  apiUrl: process.env.NEXT_PUBLIC_LANGGRAPH_API_URL || "http://localhost:8123",
});

function Chat() {
  const runtime = useLangGraphRuntime({
    stream: async function* (messages, config) {
      const { externalId } = await config.initialize();

      const stream = client.runs.stream(externalId, "my-assistant", {
        input: { messages },
        command: config.command,
      });

      for await (const event of stream) {
        yield event;
      }
    },

    create: async () => {
      const { thread_id } = await client.threads.create();
      return { externalId: thread_id };
    },

    load: async (externalId) => {
      const state = await client.threads.getState(externalId);
      return { messages: state.values.messages };
    },
  });

  return (
    <AssistantRuntimeProvider runtime={runtime}>
      <Thread />
    </AssistantRuntimeProvider>
  );
}
```

---

## config.initialize() Flow

`config.initialize()` manages thread lifecycle — calls `create` for new threads, `load` for existing ones:

```tsx
stream: async function* (messages, config) {
  const { externalId } = await config.initialize();
  yield* sendMessage({ threadId: externalId, messages, command: config.command });
}
```

---

## useLangGraphRuntime Options

```tsx
useLangGraphRuntime({
  stream: async function* (messages, config: {
    command?: LangGraphCommand,
    runConfig?: unknown,
    initialize: () => Promise<{ remoteId: string; externalId?: string }>,
  }): AsyncGenerator<LangGraphEvent>,
  autoCancelPendingToolCalls?: boolean,
  unstable_allowCancellation?: boolean,
  create?: async () => Promise<{ externalId: string }>,
  load?: async (externalId: string) => Promise<{ messages: Message[] }>,
  delete?: async (externalId: string) => Promise<void>,
  cloud?: AssistantCloud,
  adapters?: { attachments?, speech?, feedback? },
  eventHandlers?: { onMetadata?, onInfo?, onError?, onCustomEvent? },
});
```

---

## Event Types

```tsx
yield { content: [{ type: "text", text: "Hello" }] };

yield { content: [{
  type: "tool-call",
  toolCallId: "call_123",
  toolName: "search",
  args: { query: "weather" },
  argsText: '{"query":"weather"}',
  result: { temperature: 72 },    // include for completed tool calls
}] };
```

---

## Tool UI

```tsx
import { makeAssistantToolUI } from "@assistant-ui/react";

const SearchToolUI = makeAssistantToolUI({
  toolName: "tavily_search",
  render: ({ args, result, status }) => {
    if (status === "running") return <div>Searching: {args.query}...</div>;
    return <div>{result?.results?.map((r: any) => <a key={r.url} href={r.url}>{r.title}</a>)}</div>;
  },
});
```

---

## Troubleshooting

**Python "NoneType in _control_branch"** — Forward `config.command` when resuming from interrupt

**Thread not persisting** — Implement `create`/`load` callbacks; ensure LangGraph server has checkpointer

**Tool names not matching** — Tool names are case-sensitive and must match exactly
