import { execFileSync } from "node:child_process";
import path from "node:path";
import type { AssistantMessage } from "@mariozechner/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";

const cyanBold = (text: string) => `\u001b[1;36m${text}\u001b[0m`;
const tealBold = (text: string) => `\u001b[1;38;2;115;218;202m${text}\u001b[0m`;
const blueBold = (text: string) => `\u001b[1;34m${text}\u001b[0m`;
const magentaBold = (text: string) => `\u001b[1;35m${text}\u001b[0m`;
const greenBold = (text: string) => `\u001b[1;32m${text}\u001b[0m`;
const yellowBold = (text: string) => `\u001b[1;33m${text}\u001b[0m`;
const yellow = (text: string) => `\u001b[0;33m${text}\u001b[0m`;
const yellowBoldText = (text: string) => `\u001b[1;33m${text}\u001b[0m`;
const orange = (text: string) => `\u001b[0;38;2;255;158;100m${text}\u001b[0m`;
const green = (text: string) => `\u001b[0;32m${text}\u001b[0m`;
const dimBold = (text: string) => `\u001b[1;90m${text}\u001b[0m`;

const OMP_MONOREPO = `${process.env.HOME}/.local/bin/omp-monorepo`;

let currentThinkingLevel = "off";
const dirLabelCache = new Map<string, string>();

function fallbackDir(cwd: string) {
	const parent = path.basename(path.dirname(cwd));
	const current = path.basename(cwd);
	return cyanBold(`${parent}/${current}`);
}

function repoLabel(cwd: string): string {
	const cached = dirLabelCache.get(cwd);
	if (cached !== undefined) return cached;

	let rendered: string;
	try {
		const out = execFileSync(OMP_MONOREPO, [], {
			cwd,
			encoding: "utf8",
			timeout: 500,
			stdio: ["ignore", "pipe", "ignore"],
		}).trim();

		const parts = out.split(";");
		if (parts.length === 1) {
			// Not a git repo: single token ("~" or basename of cwd)
			rendered = cyanBold(parts[0] || "");
		} else if (parts.length >= 3) {
			const [repo, sub, leaf] = parts;
			const lb = dimBold("[");
			const rb = dimBold("]");
			const sep = dimBold(":");
			if (!sub) {
				// Single-package git repo
				rendered =
					leaf && leaf !== "root"
						? `${cyanBold(repo)}${lb}${yellowBold(leaf)}${rb}`
						: cyanBold(repo);
			} else {
				// Monorepo
				if (leaf && leaf !== "" && leaf !== sub) {
					rendered = `${cyanBold(repo)}${lb}${yellowBold(sub)}${sep}${yellowBold(leaf)}${rb}`;
				} else {
					rendered = `${cyanBold(repo)}${lb}${yellowBold(sub)}${rb}`;
				}
			}
		} else {
			rendered = fallbackDir(cwd);
		}
	} catch {
		rendered = fallbackDir(cwd);
	}

	dirLabelCache.set(cwd, rendered);
	return rendered;
}

function sessionId(ctx: ExtensionContext) {
	const file = ctx.sessionManager.getSessionFile();
	if (!file) return "ephemeral";
	const base = path.basename(file, ".jsonl");
	return base.includes("_") ? (base.split("_").pop() ?? base) : base;
}

function modelName(ctx: ExtensionContext) {
	const model = ctx.model;
	if (!model) return "no model";
	return model.name || model.id;
}

function fmtTokens(n: number) {
	if (n < 1000) return `${n}`;
	const value = n / 1000;
	return `${value >= 10 ? value.toFixed(0) : value.toFixed(1)}k`;
}

function tokenStats(ctx: ExtensionContext) {
	let input = 0;
	let output = 0;
	let cacheRead = 0;
	let cost = 0;

	for (const entry of ctx.sessionManager.getBranch()) {
		if (entry.type !== "message" || entry.message.role !== "assistant") continue;
		const usage = (entry.message as AssistantMessage).usage;
		if (!usage) continue;
		input += usage.input ?? 0;
		output += usage.output ?? 0;
		cacheRead += usage.cacheRead ?? 0;
		cost += usage.cost?.total ?? 0;
	}

	const usage = ctx.getContextUsage();
	const contextTokens = usage?.tokens ?? usage?.totalTokens ?? 0;
	const contextWindow = ctx.model?.contextWindow ?? 0;
	const context = contextWindow > 0 ? `${((contextTokens / contextWindow) * 100).toFixed(1)}%/${fmtTokens(contextWindow)}` : undefined;

	return { input, output, cacheRead, cost, context };
}

function renderStatusline(ctx: ExtensionContext, width: number) {
	const dir = repoLabel(ctx.cwd);
	const model = modelName(ctx);
	const context = tokenStats(ctx).context;
	const thinking = ctx.model?.reasoning ? `${dimBold("[")}${yellowBoldText(currentThinkingLevel)}${dimBold("]")}` : "";
	const modelWithThinking = `${blueBold(model)}${thinking}`;
	const contextDisplay = context
		? (() => {
				const [percent = "", total = ""] = context.split("/");
				return `${dimBold("[")}${orange(percent.replace(/\.0%$/, "%"))}${dimBold("/")}${tealBold(total)}${dimBold("]")}`;
			})()
		: undefined;

	const line1 = contextDisplay
		? `${dir} ${dimBold("with")} ${modelWithThinking} ${dimBold("at")} ${contextDisplay}`
		: `${dir} ${dimBold("with")} ${modelWithThinking}`;

	const line2 = `${dimBold("-r ")}${green(sessionId(ctx))}`;

	return [line1, line2].map((line) => truncateToWidth(line, width));
}

function defaultStatsLine(ctx: ExtensionContext, theme: { fg: (color: string, text: string) => string }, width: number) {
	const stats = tokenStats(ctx);
	const parts = [];
	if (stats.input) parts.push(`↑${fmtTokens(stats.input)}`);
	if (stats.output) parts.push(`↓${fmtTokens(stats.output)}`);
	if (stats.cacheRead) parts.push(`R${fmtTokens(stats.cacheRead)}`);

	const usingSubscription = ctx.model ? (ctx.modelRegistry as any).isUsingOAuth?.(ctx.model) === true : false;
	if (stats.cost || usingSubscription) parts.push(`$${stats.cost.toFixed(3)}${usingSubscription ? " (sub)" : ""}`);
	if (stats.context) parts.push(`${stats.context} (auto)`);

	let left = parts.join(" ");
	let leftWidth = visibleWidth(left);
	if (leftWidth > width) {
		left = truncateToWidth(left, width, "...");
		leftWidth = visibleWidth(left);
	}

	return dimBold(left);
}

function installStatusline(ctx: ExtensionContext) {
	if (!ctx.hasUI) return;

	// Keep the Claude-style two-line status block above the footer.
	ctx.ui.setWidget("custom-statusline", (_tui) => ({
		invalidate() {},
		render(width: number): string[] {
			return renderStatusline(ctx, width);
		},
	}), { placement: "belowEditor" });

	// Replace Pi's two-line default footer with only its final stats line.
	ctx.ui.setFooter((_tui, theme) => ({
		invalidate() {},
		render(width: number): string[] {
			return [defaultStatsLine(ctx, theme, width)];
		},
	}));
}

export default function customStatusline(pi: ExtensionAPI) {
	const refreshThinkingLevel = () => {
		currentThinkingLevel = pi.getThinkingLevel();
	};

	const refreshStatusline = (ctx: ExtensionContext) => {
		refreshThinkingLevel();
		installStatusline(ctx);
	};

	pi.on("session_start", (_event, ctx) => refreshStatusline(ctx));
	pi.on("model_select", (_event, ctx) => refreshStatusline(ctx));
	pi.on("thinking_level_select", (event, ctx) => {
		currentThinkingLevel = event.level;
		installStatusline(ctx);
	});
	pi.on("message_end", (_event, ctx) => refreshStatusline(ctx));
	pi.on("agent_end", (_event, ctx) => refreshStatusline(ctx));
}
