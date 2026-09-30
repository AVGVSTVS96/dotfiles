# A2A Protocol Integration

Connect assistant-ui to Agent-to-Agent (A2A) protocol backends.

## Installation

```bash
npm install @assistant-ui/react-a2a
```

## Basic Setup

```tsx
import { AssistantRuntimeProvider } from "@assistant-ui/react";
import { useA2ARuntime } from "@assistant-ui/react-a2a";
import { Thread } from "@/components/assistant-ui/thread";

function Chat() {
  const runtime = useA2ARuntime({
    stream: async function* (messages, config) {
      const response = await fetch("/api/a2a", {
        method: "POST",
        body: JSON.stringify({ messages, config }),
      });
      const reader = response.body?.getReader();
      // ... yield A2A events
    },
  });

  return (
    <AssistantRuntimeProvider runtime={runtime}>
      <Thread />
    </AssistantRuntimeProvider>
  );
}
```

## useA2ARuntime Options

```tsx
useA2ARuntime({
  stream: A2AStreamCallback,                  // Required
  autoCancelPendingToolCalls: true,           // Optional
  unstable_allowCancellation: false,          // Optional
  onSwitchToThread: async (id) => ({          // Optional: thread switching
    messages: [],
    artifacts: [],
  }),
  adapters: {
    attachments: AttachmentAdapter,
    speech: SpeechSynthesisAdapter,
    feedback: FeedbackAdapter,
  },
  eventHandlers: {
    onTaskUpdate: (event) => {},
    onArtifacts: (event) => {},
    onError: (event) => {},
  },
});
```

## Accessing A2A State

```tsx
import { useA2ATaskState, useA2AArtifacts, useA2ASend } from "@assistant-ui/react-a2a";

function MyComponent() {
  const taskState = useA2ATaskState();
  const artifacts = useA2AArtifacts();
  const send = useA2ASend();

  const onSend = async () => {
    await send([{ role: "user", content: "Hello" }], {
      contextId: "my-context",
    });
  };

  return <button onClick={onSend}>Send</button>;
}
```

## With Cloud Thread Management

```tsx
import { useA2ARuntime } from "@assistant-ui/react-a2a";
import { useCloudThreadListRuntime } from "assistant-cloud/react";

const runtime = useA2ARuntime({ stream: myStreamFunction });
const threadListRuntime = useCloudThreadListRuntime({ cloud });
```

## When to Use A2A

- Multi-agent orchestration systems
- Agents with artifact generation (files, images)
- Complex task state tracking
- Human-in-the-loop tool execution
