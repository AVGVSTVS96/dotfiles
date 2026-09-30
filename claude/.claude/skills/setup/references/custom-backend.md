# Custom Backend Integration

## useLocalRuntime

For backends returning streaming responses. Yields `ChatModelRunResult` chunks with append-only `content` parts.

```tsx
import { useLocalRuntime, AssistantRuntimeProvider } from "@assistant-ui/react";
import { Thread } from "@/components/assistant-ui/thread";

function Chat() {
  const runtime = useLocalRuntime({
    model: {
      async *run({ messages, abortSignal }) {
        const response = await fetch("/api/chat", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ messages }),
          signal: abortSignal,
        });

        const reader = response.body?.getReader();
        const decoder = new TextDecoder();
        let buffer = "";

        while (reader) {
          const { done, value } = await reader.read();
          if (done) break;

          buffer += decoder.decode(value, { stream: true });
          const parts = buffer.split("\n");
          buffer = parts.pop() ?? "";

          for (const textChunk of parts.filter(Boolean)) {
            yield { content: [{ type: "text", text: textChunk }] };
          }
        }

        if (buffer) {
          yield { content: [{ type: "text", text: buffer }] };
        }
      },
    },
  });

  return (
    <AssistantRuntimeProvider runtime={runtime}>
      <Thread />
    </AssistantRuntimeProvider>
  );
}
```

### With Tool Calls

```tsx
async *run({ messages, abortSignal }) {
  // ... fetch and parse response

  // Text content
  yield { content: [{ type: "text", text: "response text" }] };

  // Tool call (in progress)
  yield { content: [{ type: "tool-call", toolCallId: "id", toolName: "search", args: {}, argsText: "{}" }] };

  // Tool call (with result)
  yield { content: [{
    type: "tool-call",
    toolCallId: "id",
    toolName: "search",
    args: { query: "weather" },
    argsText: '{"query":"weather"}',
    result: { temperature: 72 },
  }] };
}
```

---

## useExternalStoreRuntime

For apps with existing state management. You control messages and streaming; assistant-ui renders them.

```tsx
import { useState } from "react";
import { useExternalStoreRuntime, AssistantRuntimeProvider } from "@assistant-ui/react";
import type { ThreadMessageLike, AppendMessage } from "@assistant-ui/react";
import { Thread } from "@/components/assistant-ui/thread";

type MyMessage = { id: string; role: "user" | "assistant"; content: string };

function Chat() {
  const [messages, setMessages] = useState<MyMessage[]>([]);
  const [isRunning, setIsRunning] = useState(false);

  const runtime = useExternalStoreRuntime({
    messages,
    isRunning,
    convertMessage: (msg: MyMessage): ThreadMessageLike => ({
      id: msg.id,
      role: msg.role,
      content: [{ type: "text", text: msg.content }],
    }),
    onNew: async (message: AppendMessage) => {
      const text = message.content
        .filter((p): p is { type: "text"; text: string } => p.type === "text")
        .map((p) => p.text)
        .join("");

      setMessages((prev) => [...prev, { id: crypto.randomUUID(), role: "user", content: text }]);
      setIsRunning(true);

      // Your API call + streaming logic here
      const response = await myAPI.chat(text);

      setMessages((prev) => [...prev, {
        id: crypto.randomUUID(),
        role: "assistant",
        content: response.text,
      }]);
      setIsRunning(false);
    },
  });

  return (
    <AssistantRuntimeProvider runtime={runtime}>
      <Thread />
    </AssistantRuntimeProvider>
  );
}
```
