import type { Api, Context, Model, SimpleStreamOptions } from "@earendil-works/pi-ai";
import {
  streamSimpleAnthropic,
  streamSimpleOpenAICodexResponses,
  streamSimpleOpenAIResponses,
} from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const OPENAI_FAST = ["openai/gpt-5.5", "openai-codex/gpt-5.5"];
const CLAUDE_FAST = ["claude-opus-4-8", "claude-opus-4-7", "claude-opus-4-6"];
const FAST_MODE_BETA = "fast-mode-2026-02-01";

// Anthropic prices Fast Mode as a per-model multiplier on standard rates. pi's registry
// only has standard rates and the API returns no price, so this table is irreducible.
// Verify 4.8 against your live registry's standard Opus 4.8 rate.
const CLAUDE_FAST_MULTIPLIER: Record<string, number> = {
  "claude-opus-4-8": 2, // fast $10/$50 vs standard $5/$25
  "claude-opus-4-7": 6, // fast $30/$150 vs standard $5/$25
  "claude-opus-4-6": 6,
};

const matches = (m: Model<Api>, ids: string[]) =>
  ids.some((id) => id === m.id || id === `${m.provider}/${m.id}` || m.id.startsWith(id));

const fastPricedModel = (m: Model<Api>): Model<Api> => {
  const k = CLAUDE_FAST_MULTIPLIER[m.id];
  if (!k || !m.cost) return m;
  return {
    ...m,
    cost: {
      input: m.cost.input * k,
      output: m.cost.output * k,
      cacheRead: m.cost.cacheRead * k,
      cacheWrite: m.cost.cacheWrite * k,
    },
  };
};

type Wrapper = {
  api: Api;
  stream: any;
  models: string[];
  inject: (payload: any) => void;
  beta?: string;
  priceModel?: (m: Model<Api>) => Model<Api>;
};

const WRAPPERS: Wrapper[] = [
  {
    api: "openai-responses",
    stream: streamSimpleOpenAIResponses,
    models: OPENAI_FAST,
    inject: (p) => {
      p.service_tier = "priority";
    },
  },
  // Codex priority pricing relies on the API echoing service_tier; may under-report if
  // it returns "default". Accepted — codex is always run in priority.
  {
    api: "openai-codex-responses",
    stream: streamSimpleOpenAICodexResponses,
    models: OPENAI_FAST,
    inject: (p) => {
      p.service_tier = "priority";
    },
  },
  {
    api: "anthropic-messages",
    stream: streamSimpleAnthropic,
    models: CLAUDE_FAST,
    inject: (p) => {
      p.speed = "fast";
    },
    beta: FAST_MODE_BETA,
    priceModel: fastPricedModel,
  },
];

export default function fastMode(pi: ExtensionAPI) {
  let fast = false;

  const activeFor = (m?: Model<Api>) => !!m && fast && WRAPPERS.some((w) => matches(m, w.models));

  const sync = (m: Model<Api> | undefined, ctx: any) => {
    ctx.ui.setStatus("fast", activeFor(m) ? "fast: on" : "fast: off");
    pi.events.emit("fast:state", { active: activeFor(m) });
  };

  // gpt-5.5 auto-enables (economical); everything else (incl. Claude) resets off.
  const derive = (m: Model<Api> | undefined, ctx: any) => {
    fast = !!m && matches(m, OPENAI_FAST);
    sync(m, ctx);
  };

  pi.registerCommand("fast", {
    description: "Fast mode (this session): /fast on | /fast off | /fast status",
    handler: async (args, ctx) => {
      const arg = args.trim().toLowerCase();
      if (arg === "on") fast = true;
      else if (arg === "off") fast = false;
      else if (arg && arg !== "status")
        return ctx.ui.notify("Usage: /fast [on|off|status]", "warning");
      sync(ctx.model, ctx);
      ctx.ui.notify(
        `Fast mode ${activeFor(ctx.model) ? "on" : "off"}${ctx.model ? ` for ${ctx.model.id}` : ""}`,
        "info",
      );
    },
  });

  pi.on("session_start", async (_event, ctx) => derive(ctx.model, ctx));
  pi.on("model_select", async (event, ctx) => derive(event.model, ctx));

  for (const w of WRAPPERS) {
    pi.registerProvider(`fast-${w.api}-wrapper`, {
      api: w.api,
      streamSimple(model: Model<Api>, context: Context, options?: SimpleStreamOptions) {
        if (!(fast && matches(model, w.models))) return w.stream(model, context, options);
        const m = w.priceModel ? w.priceModel(model) : model;
        return w.stream(m, context, {
          ...options,
          headers: w.beta ? { ...options?.headers, "anthropic-beta": w.beta } : options?.headers,
          onPayload: async (p: any, mm: Model<Api>) => {
            w.inject(p);
            return (await options?.onPayload?.(p, mm)) ?? p;
          },
        });
      },
    });
  }
}
