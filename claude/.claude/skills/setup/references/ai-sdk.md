# AI SDK v6 Integration

## Basic Setup

The CLI (`npx assistant-ui init`) generates the page component and API route. This reference covers options and patterns beyond the defaults.

---

## useChatRuntime Options

```tsx
const runtime = useChatRuntime({
  transport: new AssistantChatTransport({
    api: "/api/chat",
    headers: { "X-Custom-Header": "value" },
    body: { model: "gpt-4o" },         // extra fields sent with each request
  }),

  initialMessages: [
    { role: "assistant", content: "Hello! How can I help?" },
  ],

  onError: (error) => {
    console.error("Chat error:", error);
  },

  cloud: assistantCloud,               // for thread persistence

  adapters: {
    attachments: myAttachmentAdapter,
    feedback: myFeedbackAdapter,
  },
});
```

---

## Tools

### Backend

```ts
import { openai } from "@ai-sdk/openai";
import { streamText, tool, convertToModelMessages, type UIMessage } from "ai";
import { z } from "zod";

const tools = {
  get_weather: tool({
    description: "Get weather for a city",
    parameters: z.object({
      city: z.string().describe("City name"),
    }),
    execute: async ({ city }) => {
      return { temperature: 22, city, unit: "celsius" };
    },
  }),
};

export async function POST(req: Request) {
  const { messages }: { messages: UIMessage[] } = await req.json();

  const result = streamText({
    model: openai("gpt-4o"),
    messages: await convertToModelMessages(messages),
    tools,
    maxSteps: 5,
  });

  return result.toUIMessageStreamResponse();
}
```

### Frontend Tool UI

```tsx
import { makeAssistantToolUI } from "@assistant-ui/react";

const WeatherToolUI = makeAssistantToolUI({
  toolName: "get_weather",
  render: ({ args, result, status }) => {
    if (status === "running") return <div>Loading weather for {args.city}...</div>;
    return (
      <div className="p-4 rounded bg-blue-50">
        <strong>{result?.city}</strong>: {result?.temperature}°{result?.unit}
      </div>
    );
  },
});

// Register alongside Thread:
<AssistantRuntimeProvider runtime={runtime}>
  <Thread />
  <WeatherToolUI />
</AssistantRuntimeProvider>
```

---

## Cloud Persistence

```tsx
import { AssistantCloud } from "assistant-cloud";
import { AssistantRuntimeProvider } from "@assistant-ui/react";
import { useChatRuntime, AssistantChatTransport } from "@assistant-ui/react-ai-sdk";
import { Thread } from "@/components/assistant-ui/thread";
import { ThreadList } from "@/components/assistant-ui/thread-list";

const cloud = new AssistantCloud({
  baseUrl: process.env.NEXT_PUBLIC_ASSISTANT_BASE_URL!,
  authToken: async () => getAuthToken(),
});

function ChatPage() {
  const runtime = useChatRuntime({
    transport: new AssistantChatTransport({ api: "/api/chat" }),
    cloud,
  });

  return (
    <AssistantRuntimeProvider runtime={runtime}>
      <div className="flex h-dvh">
        <ThreadList />
        <Thread />
      </div>
    </AssistantRuntimeProvider>
  );
}
```

---

## Error Handling

```tsx
const runtime = useChatRuntime({
  transport: new AssistantChatTransport({ api: "/api/chat" }),
  onError: (error) => {
    if (error.message.includes("rate limit")) {
      toast.error("Too many requests. Please wait.");
    } else if (error.message.includes("context length")) {
      toast.error("Conversation too long. Try starting a new chat.");
    } else {
      toast.error("Something went wrong. Please try again.");
    }
  },
});
```

---

## Troubleshooting

**Streaming stops mid-response** — Increase `maxSteps` when using tools

**Tool results not showing** — Return from `tool.execute()`, don't just mutate state

**Messages not converting** — Use `await convertToModelMessages(messages)` in API route
