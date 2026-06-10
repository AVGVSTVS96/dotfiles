import type { Api, Context, Model, SimpleStreamOptions } from "@earendil-works/pi-ai";
import {
  streamSimpleAnthropic,
  streamSimpleOpenAICodexResponses,
  streamSimpleOpenAIResponses,
} from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const OPENAI_FAST_MODELS = ["openai/gpt-5.5", "openai-codex/gpt-5.5"];
const CLAUDE_FAST_MODELS = ["claude-opus-4-8", "claude-opus-4-7", "claude-opus-4-6"];
const CLAUDE_FAST_BETA = "fast-mode-2026-02-01";

// Anthropic prices Fast Mode as a per-model multiplier on standard rates. pi's registry
// only has standard rates and the API returns no price, so this table is irreducible.
const CLAUDE_FAST_MULTIPLIER: Record<string, number> = {
  "claude-opus-4-8": 2, // fast $10/$50 vs standard $5/$25
  "claude-opus-4-7": 6, // fast $30/$150 vs standard $5/$25
  "claude-opus-4-6": 6,
};

const matchesModel = (model: Model<Api>, ids: string[]) =>
  ids.some(
    (id) => id === model.id || id === `${model.provider}/${model.id}` || model.id.startsWith(id),
  );

const applyFastPricing = (model: Model<Api>): Model<Api> => {
  const multiplier = CLAUDE_FAST_MULTIPLIER[model.id];
  if (!multiplier || !model.cost) return model;
  return {
    ...model,
    cost: {
      input: model.cost.input * multiplier,
      output: model.cost.output * multiplier,
      cacheRead: model.cost.cacheRead * multiplier,
      cacheWrite: model.cost.cacheWrite * multiplier,
    },
  };
};

const errorMessage = (error: any) =>
  [error?.error?.error?.message, error?.error?.message, error?.message].filter(Boolean).join("\n");

const isClaudeFastModeRejection = (error: any) =>
  error?.status === 400 &&
  (error?.type === "invalid_request_error" ||
    error?.error?.error?.type === "invalid_request_error") &&
  /\bspeed\b|fast-mode-2026-02-01/.test(errorMessage(error));

// Stream the primary (fast) request; if it's rejected for a recognized reason,
// notify and transparently restart on the standard request.
async function* withFallback<T>(
  shouldFallback: (error: any) => boolean,
  onFallback: () => void,
  runPrimary: () => AsyncIterable<T>,
  runFallback: () => AsyncIterable<T>,
): AsyncIterable<T> {
  try {
    yield* runPrimary();
  } catch (error) {
    if (!shouldFallback(error)) throw error;
    onFallback();
    yield* runFallback();
  }
}

type FastProvider = {
  api: Api;
  stream: any;
  models: string[];
  // Extra stream options merged in while fast mode is active.
  extraOptions?: Record<string, unknown>;
  // Shallow-merged into the raw request body via onPayload, for fields the typed
  // options don't expose (e.g. Anthropic's `speed`).
  payloadPatch?: Record<string, unknown>;
  // anthropic-beta header required to opt into the feature.
  betaHeader?: string;
  // Reprice the model while fast mode is active (standard rates -> fast rates).
  reprice?: (model: Model<Api>) => Model<Api>;
  // When set, a rejection matching this predicate falls back to standard mode.
  fallbackOnReject?: (error: any) => boolean;
};

const FAST_PROVIDERS: FastProvider[] = [
  // service_tier "priority" is a first-class option; the OpenAI stream also uses it to price
  // usage. Priority pricing relies on the API echoing service_tier back — it may under-report
  // if the API returns "default" -- acceptable because we default to priority.
  {
    api: "openai-responses",
    stream: streamSimpleOpenAIResponses,
    models: OPENAI_FAST_MODELS,
    extraOptions: { serviceTier: "priority" },
  },
  {
    api: "openai-codex-responses",
    stream: streamSimpleOpenAICodexResponses,
    models: OPENAI_FAST_MODELS,
    extraOptions: { serviceTier: "priority" },
  },
  {
    api: "anthropic-messages",
    stream: streamSimpleAnthropic,
    models: CLAUDE_FAST_MODELS,
    payloadPatch: { speed: "fast" },
    betaHeader: CLAUDE_FAST_BETA,
    reprice: applyFastPricing,
    fallbackOnReject: isClaudeFastModeRejection,
  },
];

export default function fastMode(pi: ExtensionAPI) {
  let fastEnabled = false;
  let lastUi: any;

  const activeFor = (model?: Model<Api>) =>
    !!model && fastEnabled && FAST_PROVIDERS.some((p) => matchesModel(model, p.models));

  const syncStatus = (model: Model<Api> | undefined, ctx?: any) => {
    (ctx?.ui ?? lastUi)?.setStatus("fast", activeFor(model) ? "fast: on" : "fast: off");
    pi.events.emit("fast:state", { active: activeFor(model) });
  };

  // gpt-5.5 auto-enables fast mode (it's the economical default);
  // Claude models reset to off and must always be turned on explicitly.
  const applyModel = (model: Model<Api> | undefined, ctx: any) => {
    lastUi = ctx.ui;
    fastEnabled = !!model && matchesModel(model, OPENAI_FAST_MODELS);
    syncStatus(model, ctx);
  };

  pi.registerCommand("fast", {
    description: "Fast mode (this session): /fast on | /fast off | /fast status",
    handler: async (args, ctx) => {
      lastUi = ctx.ui;
      const arg = args.trim().toLowerCase();
      if (arg === "on") fastEnabled = true;
      else if (arg === "off") fastEnabled = false;
      else if (arg && arg !== "status")
        return ctx.ui.notify("Usage: /fast [on|off|status]", "warning");
      syncStatus(ctx.model, ctx);
      ctx.ui.notify(
        `Fast mode ${activeFor(ctx.model) ? "on" : "off"}${ctx.model ? ` for ${ctx.model.id}` : ""}`,
        "info",
      );
    },
  });

  pi.on("session_start", async (_event, ctx) => applyModel(ctx.model, ctx));
  pi.on("model_select", async (event, ctx) => applyModel(event.model, ctx));

  for (const provider of FAST_PROVIDERS) {
    pi.registerProvider(`fast-${provider.api}-wrapper`, {
      api: provider.api,
      streamSimple(model: Model<Api>, context: Context, options?: SimpleStreamOptions) {
        const runStandard = () => provider.stream(model, context, options);
        if (!(fastEnabled && matchesModel(model, provider.models))) return runStandard();

        const fastModel = provider.reprice ? provider.reprice(model) : model;
        const fastOptions = { ...options, ...provider.extraOptions };

        if (provider.betaHeader) {
          fastOptions.headers = { ...options?.headers, "anthropic-beta": provider.betaHeader };
        }
        if (provider.payloadPatch) {
          const patch = provider.payloadPatch;
          fastOptions.onPayload = async (payload: any, payloadModel: Model<Api>) => {
            Object.assign(payload, patch);
            return (await options?.onPayload?.(payload, payloadModel)) ?? payload;
          };
        }

        const runFast = () => provider.stream(fastModel, context, fastOptions);
        if (!provider.fallbackOnReject) return runFast();

        const onFallback = () => {
          fastEnabled = false;
          syncStatus(model);
          pi.sendMessage({
            customType: "fast-warning",
            content: "⚡ Claude fast mode failed; turning fast mode off and retrying standard mode.",
            display: true,
          });
        };

        return withFallback(provider.fallbackOnReject, onFallback, runFast, runStandard);
      },
    });
  }
}
