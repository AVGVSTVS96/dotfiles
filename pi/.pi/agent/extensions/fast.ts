import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import type { Api, Context, Model, SimpleStreamOptions } from "@earendil-works/pi-ai";
import { clampThinkingLevel, streamOpenAICodexResponses, streamOpenAIResponses } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { getAgentDir } from "@earendil-works/pi-coding-agent";

type ServiceTier = "priority";

type Config = {
	enabled: boolean;
	models: string[];
	serviceTier: ServiceTier;
};

type FastState = Config & {
	configPath: string;
};

const configPath = join(getAgentDir(), "fast.json");

const defaultConfig: Config = {
	enabled: true,
	// Use provider/model entries for safety. Plain model ids also work and match any provider.
	models: ["openai/gpt-5.5", "openai-codex/gpt-5.5"],
	serviceTier: "priority",
};

function normalizeConfig(value: Partial<Config> | undefined): Config {
	return {
		...defaultConfig,
		...value,
		models: Array.isArray(value?.models) ? value.models : defaultConfig.models,
		serviceTier: value?.serviceTier === "priority" ? value.serviceTier : defaultConfig.serviceTier,
	};
}

function loadConfig(): Config {
	if (!existsSync(configPath)) return defaultConfig;

	try {
		return normalizeConfig(JSON.parse(readFileSync(configPath, "utf8")));
	} catch {
		return defaultConfig;
	}
}

function saveConfig(config: Config) {
	mkdirSync(getAgentDir(), { recursive: true });
	writeFileSync(configPath, `${JSON.stringify(config, null, 2)}\n`);
}

function buildBaseOptions(model: Model<Api>, options?: SimpleStreamOptions) {
	const clampedReasoning = options?.reasoning ? clampThinkingLevel(model, options.reasoning) : undefined;

	return {
		temperature: options?.temperature,
		maxTokens: options?.maxTokens ?? (model.maxTokens > 0 ? Math.min(model.maxTokens, 32_000) : undefined),
		signal: options?.signal,
		apiKey: options?.apiKey,
		transport: options?.transport,
		cacheRetention: options?.cacheRetention,
		sessionId: options?.sessionId,
		headers: options?.headers,
		onPayload: options?.onPayload,
		onResponse: options?.onResponse,
		timeoutMs: options?.timeoutMs,
		maxRetries: options?.maxRetries,
		maxRetryDelayMs: options?.maxRetryDelayMs,
		metadata: options?.metadata,
		reasoningEffort: clampedReasoning && clampedReasoning !== "off" ? clampedReasoning : undefined,
	};
}

export default function fastMode(pi: ExtensionAPI) {
	let config = loadConfig();

	const fastEnabledFor = (model: Model<Api>) =>
		config.enabled && (config.models.includes(`${model.provider}/${model.id}`) || config.models.includes(model.id));

	const state = (): FastState => ({ ...config, configPath });
	const emitState = () => pi.events.emit("fast:state", state());
	const status = () => (config.enabled ? "fast: on" : "fast: off");

	pi.registerCommand("fast", {
		description: "Set fast mode: /fast on | /fast off | /fast status",
		handler: async (args, ctx) => {
			const arg = args.trim().toLowerCase();

			if (arg === "on") {
				config = { ...config, enabled: true };
			} else if (arg === "off") {
				config = { ...config, enabled: false };
			} else if (arg === "status" || arg === "") {
				ctx.ui.notify(`Fast mode is ${config.enabled ? "on" : "off"} for: ${config.models.join(", ")}`, "info");
				ctx.ui.setStatus("fast", status());
				emitState();
				return;
			} else {
				ctx.ui.notify("Usage: /fast [on|off|status]", "warning");
				return;
			}

			saveConfig(config);
			ctx.ui.setStatus("fast", status());
			emitState();
			ctx.ui.notify(`Fast mode ${config.enabled ? "enabled" : "disabled"}`, "info");
		},
	});

	pi.on("session_start", async (_event, ctx) => {
		ctx.ui.setStatus("fast", status());
		emitState();
	});

	pi.registerProvider("fast-openai-responses-wrapper", {
		api: "openai-responses",
		streamSimple(model: Model<Api>, context: Context, options?: SimpleStreamOptions) {
			return streamOpenAIResponses(model as Model<"openai-responses">, context, {
				...buildBaseOptions(model, options),
				serviceTier: fastEnabledFor(model) ? config.serviceTier : undefined,
			});
		},
	});

	pi.registerProvider("fast-codex-responses-wrapper", {
		api: "openai-codex-responses",
		streamSimple(model: Model<Api>, context: Context, options?: SimpleStreamOptions) {
			return streamOpenAICodexResponses(model as Model<"openai-codex-responses">, context, {
				...buildBaseOptions(model, options),
				serviceTier: fastEnabledFor(model) ? config.serviceTier : undefined,
			});
		},
	});
}
