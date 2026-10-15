/**
 * /context — context usage report (Claude Code style)
 *
 * Shows how much of the model's context window is used, how much is free,
 * and a per-category breakdown: system prompt, tool declarations, input
 * (user messages + tool results) and output (assistant messages).
 *
 * Each invocation appends a one-shot report to the transcript as a custom
 * session entry: it scrolls away with the conversation history like any
 * other message and is never sent to the LLM.
 */

import { estimateTokens, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";

const ENTRY_TYPE = "context-report";
const BAR_WIDTH = 20;

/** Structural view of a transcript message — only the fields we need. */
interface TranscriptMessage {
	role: string;
	content?: unknown;
	sections?: Record<string, string | null>;
	toolsAdded?: Array<{ name: string } & Record<string, unknown>>;
	toolsRemoved?: Array<{ name: string }>;
}

/** Snapshot persisted as the custom entry's data. */
interface ReportData {
	modelLabel: string;
	contextWindow: number | null;
	/** Authoritative used tokens from the session (null = unknown, e.g. right after compaction). */
	usedTokens: number | null;
	system: number;
	tools: number;
	input: number;
	output: number;
	estimatedTotal: number;
	timestamp: number;
}

function fmt(n: number): string {
	return n.toLocaleString("en-US");
}

function pct(part: number, whole: number): number {
	return whole > 0 ? (part / whole) * 100 : 0;
}

/**
 * Walk the projected session messages and bucket estimated tokens by category.
 * Tool declarations are replayed across system messages so a tool that is
 * removed and re-added is counted once for its final definition.
 */
function computeReport(ctx: {
	getContextUsage(): { tokens: number | null; contextWindow: number } | undefined;
	sessionManager: { buildSessionProjection(): { messages: unknown[] } };
	model?: { provider?: string; id?: string } | null;
}): Omit<ReportData, "timestamp"> {
	const usage = ctx.getContextUsage();
	const projection = ctx.sessionManager.buildSessionProjection();

	let system = 0;
	let input = 0;
	let output = 0;
	const tools = new Map<string, unknown>();

	for (const raw of projection.messages) {
		const m = raw as TranscriptMessage;
		switch (m.role) {
			case "system": {
				for (const t of m.toolsAdded ?? []) tools.set(t.name, t);
				for (const r of m.toolsRemoved ?? []) tools.delete(r.name);
				// Count prompt text/sections only — tool JSON goes to the tools bucket.
				system += estimateTokens({ ...m, toolsAdded: undefined } as never);
				break;
			}
			case "assistant":
				output += estimateTokens(m as never);
				break;
			default:
				// user, toolResult, custom, bashExecution, branchSummary, compactionSummary…
				input += estimateTokens(m as never);
				break;
		}
	}

	let toolTokens = 0;
	for (const def of tools.values()) {
		toolTokens += Math.ceil(JSON.stringify(def).length / 4);
	}

	return {
		modelLabel: ctx.model ? `${ctx.model.provider ?? ""}/${ctx.model.id}` : "no model",
		contextWindow: usage?.contextWindow ?? null,
		usedTokens: usage?.tokens ?? null,
		system,
		tools: toolTokens,
		input,
		output,
		estimatedTotal: system + toolTokens + input + output,
	};
}

function bar(fraction: number): string {
	const filled = Math.max(fraction > 0 ? 1 : 0, Math.min(BAR_WIDTH, Math.round(fraction * BAR_WIDTH)));
	return "█".repeat(filled) + "░".repeat(BAR_WIDTH - filled);
}

/** Themed report lines for the given viewport width (every line truncated to fit). */
function renderThemed(r: ReportData, theme: { fg(color: string, text: string): string }): (width: number) => string[] {
	const window = r.contextWindow;
	const used = r.usedTokens ?? r.estimatedTotal;
	const free = window != null ? Math.max(0, window - used) : 0;
	const denom = window ?? (r.estimatedTotal > 0 ? r.estimatedTotal : 1);

	return (width: number) => {
		// Every line must fit the viewport — long model ids (e.g. local server URLs)
		// would otherwise crash the TUI renderer.
		const lines: string[] = [];
		const push = (line: string) => lines.push(truncateToWidth(line, width));

		push(theme.fg("accent", `Context Usage — ${r.modelLabel}`));
		push("");
		if (window != null && window > 0) {
			push(`${theme.fg("dim", "Window")}   ${fmt(window)} tokens`);
			const usedColor = pct(used, window) >= 85 ? "error" : pct(used, window) >= 60 ? "warning" : "success";
			const estNote = r.usedTokens == null ? theme.fg("dim", "  [estimated]") : "";
			push(`${theme.fg("dim", "Used")}     ${theme.fg(usedColor, `${fmt(used)} tokens (${pct(used, window).toFixed(1)}%)`)}${estNote}`);
			push(`${theme.fg("dim", "Free")}     ${fmt(free)} tokens (${pct(free, window).toFixed(1)}%)`);
		} else {
			push(`${theme.fg("dim", "Used (estimated)")}   ${fmt(r.estimatedTotal)} tokens`);
			push(theme.fg("dim", "Context window unknown for the current model."));
		}
		push("");
		const rows: Array<[string, number]> = [
			["System prompt", r.system],
			["Tools", r.tools],
			["Input", r.input],
			["Output", r.output],
		];
		for (const [label, tokens] of rows) {
			const p = pct(tokens, denom);
			const barColor = p >= 85 ? "error" : p >= 60 ? "warning" : "text";
			push(`${theme.fg("dim", label.padEnd(14))} ${fmt(tokens).padStart(9)}  ${p.toFixed(1).padStart(5)}%  ${theme.fg(barColor, bar(p / 100))}`);
		}
		return lines;
	};
}

/** Plain-text report for non-TUI fallbacks. */
function renderPlain(r: ReportData): string[] {
	const window = r.contextWindow;
	const used = r.usedTokens ?? r.estimatedTotal;
	const free = window != null ? Math.max(0, window - used) : 0;
	const denom = window ?? (r.estimatedTotal > 0 ? r.estimatedTotal : 1);

	const lines: string[] = [];
	lines.push(`Context Usage — ${r.modelLabel}`);
	lines.push("");
	if (window != null && window > 0) {
		lines.push(`Window   ${fmt(window)} tokens`);
		lines.push(`Used     ${fmt(used)} tokens (${pct(used, window).toFixed(1)}%)${r.usedTokens == null ? "  [estimated]" : ""}`);
		lines.push(`Free     ${fmt(free)} tokens (${pct(free, window).toFixed(1)}%)`);
	} else {
		lines.push(`Used (estimated)   ${fmt(r.estimatedTotal)} tokens`);
		lines.push("Context window unknown for the current model.");
	}
	lines.push("");
	for (const [label, tokens] of [
		["System prompt", r.system],
		["Tools", r.tools],
		["Input", r.input],
		["Output", r.output],
	] as Array<[string, number]>) {
		const p = pct(tokens, denom);
		lines.push(`${label.padEnd(14)} ${fmt(tokens).padStart(9)}  ${p.toFixed(1).padStart(5)}%  ${bar(p / 100)}`);
	}
	return lines;
}

export default function (pi: ExtensionAPI) {
	// Render past reports in the transcript (TUI only; other modes ignore entries).
	pi.registerEntryRenderer<ReportData>(ENTRY_TYPE, (entry, { expanded }, theme) => {
		const data = entry.data;
		if (!data) return undefined;

		return {
			invalidate() {},
			render(width: number): string[] {
				const lines = renderThemed(data, theme)(width);
				if (expanded && Number.isFinite(data.timestamp)) {
					lines.push(truncateToWidth(theme.fg("dim", `captured ${new Date(data.timestamp).toLocaleString()}`), width));
				}
				return lines;
			},
		};
	});

	pi.registerCommand("context", {
		description: "Append a context window usage report to the transcript",
		handler: async (_args, ctx) => {
			const report: ReportData = { ...computeReport(ctx), timestamp: Date.now() };
			pi.appendEntry(ENTRY_TYPE, report);

			if (ctx.mode !== "tui" && ctx.hasUI) {
				const window = report.contextWindow;
				const used = report.usedTokens ?? report.estimatedTotal;
				ctx.ui.notify(
					window
						? `Context: ${fmt(used)} / ${fmt(window)} tokens (${pct(used, window).toFixed(1)}%) — sys ${fmt(report.system)}, tools ${fmt(report.tools)}, in ${fmt(report.input)}, out ${fmt(report.output)}`
						: `Context (estimated): ${fmt(report.estimatedTotal)} tokens`,
					"info"
				);
			} else if (ctx.mode !== "tui" && !ctx.hasUI) {
				for (const line of renderPlain(report)) console.error(line);
			}
		},
	});
}
