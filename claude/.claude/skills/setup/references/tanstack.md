# TanStack Start + Vite Setup

**Working example:** `examples/with-tanstack/` in the assistant-ui monorepo.

## Installation

```bash
npm install @assistant-ui/react @tanstack/react-router @tanstack/react-start
npm install tailwindcss @tailwindcss/vite vite @vitejs/plugin-react vite-tsconfig-paths
```

---

## Vite Configuration

```ts
// vite.config.ts
import { defineConfig } from "vite";
import { tanstackStart } from "@tanstack/react-start/plugin/vite";
import viteReact from "@vitejs/plugin-react";
import viteTsConfigPaths from "vite-tsconfig-paths";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  plugins: [
    viteTsConfigPaths({ projects: ["./tsconfig.json"] }),
    tailwindcss(),
    tanstackStart(),
    viteReact(),
  ],
});
```

---

## Route with assistant-ui

```tsx
// src/routes/index.tsx
import { createFileRoute } from "@tanstack/react-router";
import { Thread } from "@/components/assistant-ui/thread";
import { MyRuntimeProvider } from "@/components/MyRuntimeProvider";

export const Route = createFileRoute("/")({ component: App });

function App() {
  return (
    <MyRuntimeProvider>
      <main className="h-dvh">
        <Thread />
      </main>
    </MyRuntimeProvider>
  );
}
```

---

## Runtime Provider

Uses `useExternalStoreRuntime` — same pattern as any non-Next.js setup:

```tsx
// src/components/MyRuntimeProvider.tsx
import { useState, type ReactNode } from "react";
import {
  useExternalStoreRuntime,
  ThreadMessageLike,
  AppendMessage,
  AssistantRuntimeProvider,
} from "@assistant-ui/react";

type MyMessage = { id: string; role: "user" | "assistant"; content: string };

const convertMessage = (message: MyMessage): ThreadMessageLike => ({
  id: message.id,
  role: message.role,
  content: [{ type: "text", text: message.content }],
});

export function MyRuntimeProvider({ children }: { children: ReactNode }) {
  const [isRunning, setIsRunning] = useState(false);
  const [messages, setMessages] = useState<MyMessage[]>([]);

  const onNew = async (message: AppendMessage) => {
    if (message.content[0]?.type !== "text")
      throw new Error("Only text messages are supported");

    const input = message.content[0].text;
    setMessages((prev) => [...prev, { id: crypto.randomUUID(), role: "user", content: input }]);
    setIsRunning(true);

    try {
      const stream = await fetchStream([...messages, { id: "", role: "user", content: input }]);
      const assistantId = crypto.randomUUID();
      setMessages((prev) => [...prev, { id: assistantId, role: "assistant", content: "" }]);

      for await (const chunk of stream) {
        setMessages((prev) =>
          prev.map((m) => m.id === assistantId ? { ...m, content: m.content + chunk } : m)
        );
      }
    } finally {
      setIsRunning(false);
    }
  };

  const runtime = useExternalStoreRuntime({ isRunning, messages, convertMessage, onNew });

  return (
    <AssistantRuntimeProvider runtime={runtime}>
      {children}
    </AssistantRuntimeProvider>
  );
}
```

`fetchStream(...)` above is an application-specific helper you implement (for example, wrapping `fetch("/api/chat")` and yielding text chunks).

---

## Key Dependencies

```json
{
  "@assistant-ui/react": "latest",
  "@tanstack/react-router": "^1.158.0",
  "@tanstack/react-start": "^1.158.0",
  "@tailwindcss/vite": "^4.1.18",
  "vite-tsconfig-paths": "^6.0.5",
  "react": "^19.2.4",
  "vite": "^7.3.1"
}
```

---

## Notes

- Uses `useExternalStoreRuntime` (not `useChatRuntime` — that's for AI SDK + Next.js)
- TanStack Start provides SSR and file-based routing
- Tailwind v4 via Vite plugin
- Set `isRunning` during streaming for proper loading state
