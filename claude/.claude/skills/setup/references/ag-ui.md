# AG-UI Protocol Integration

Connect assistant-ui to [AG-UI](https://github.com/ag-ui-protocol/ag-ui) compatible agent backends.

## Installation

```bash
npm install @assistant-ui/react-ag-ui @ag-ui/client
```

## Basic Setup

```tsx
"use client";

import { useMemo } from "react";
import { AssistantRuntimeProvider } from "@assistant-ui/react";
import { Thread } from "@/components/assistant-ui/thread";
import { HttpAgent } from "@ag-ui/client";
import { useAgUiRuntime } from "@assistant-ui/react-ag-ui";

function Chat() {
  const agent = useMemo(() => new HttpAgent({
    url: process.env.NEXT_PUBLIC_AGUI_AGENT_URL ?? "http://localhost:8000/agent",
    headers: { Accept: "text/event-stream" },
  }), []);

  const runtime = useAgUiRuntime({
    agent,
    logger: {
      debug: (...args) => console.debug("[agui]", ...args),
      error: (...args) => console.error("[agui]", ...args),
    },
  });

  return (
    <AssistantRuntimeProvider runtime={runtime}>
      <Thread />
    </AssistantRuntimeProvider>
  );
}
```

## useAgUiRuntime Options

```tsx
useAgUiRuntime({
  agent: HttpAgent,           // Required
  logger: { debug, error },   // Optional
  showThinking: true,         // Optional: show reasoning content
  onError: (e) => {},         // Optional
  onCancel: () => {},         // Optional
  adapters: {
    attachments: AttachmentAdapter,
    speech: SpeechSynthesisAdapter,
    dictation: DictationAdapter,
    feedback: FeedbackAdapter,
    history: ThreadHistoryAdapter,
    threadList: {
      threadId: "thread-id",
      onSwitchToNewThread: async () => {},
      onSwitchToThread: async (id) => ({ messages: [] }),
    },
  },
});
```

## AG-UI Event Types

- `RUN_STARTED` / `RUN_FINISHED` / `RUN_CANCELLED` / `RUN_ERROR`
- `TEXT_MESSAGE_START` / `TEXT_MESSAGE_CONTENT` / `TEXT_MESSAGE_END`
- `THINKING_START` / `THINKING_TEXT_MESSAGE_*` / `THINKING_END`
- `TOOL_CALL_START` / `TOOL_CALL_ARGS` / `TOOL_CALL_END` / `TOOL_CALL_RESULT`
- `STATE_SNAPSHOT` / `STATE_DELTA` / `MESSAGES_SNAPSHOT`

## When to Use AG-UI

- Building agents with [AG-UI protocol](https://github.com/ag-ui-protocol/ag-ui)
- Need streaming with thinking/reasoning visibility
- Want protocol-level compatibility across agent frameworks
