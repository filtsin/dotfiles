/**
 * Review Mode Extension
 *
 * Human-in-the-loop mode: every file change the agent makes (edit / write)
 * is shown as a diff and requires explicit approval before it is applied.
 *
 * Features:
 * - /review command (or --review flag) to toggle review mode
 * - Footer status indicator while active
 * - Diff preview in the console (colored, intra-line highlighting)
 * - "n" opens a side-by-side diff split in neovim (TUI suspends while nvim runs);
 *   the right pane (new content) is editable — save with :wq to fold your edits
 *   into the diff (the real file is never touched until you approve)
 * - a = approve, r / Esc = reject
 * - Non-interactive sessions: changes are blocked (fail-safe)
 */

import { spawnSync } from "node:child_process";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import {
	generateDiffString,
	renderDiff,
	type ExtensionAPI,
	type ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import {
	matchesKey,
	truncateToWidth,
	type Component,
} from "@earendil-works/pi-tui";
import type { Theme } from "@earendil-works/pi-coding-agent";

type ReviewDecision = "approve" | "reject" | "nvim";

interface ReviewState {
	enabled: boolean;
}

// ---------------------------------------------------------------------------
// Diff computation
// ---------------------------------------------------------------------------

function readExisting(absPath: string): string {
	try {
		return fs.readFileSync(absPath, "utf8");
	} catch {
		return "";
	}
}

function applyEditsLocally(content: string, edits: { oldText: string; newText: string }[]): string {
	let out = content;
	for (const e of edits) {
		const idx = out.indexOf(e.oldText);
		if (idx === -1) continue; // tool will report the real error
		out = out.slice(0, idx) + e.newText + out.slice(idx + e.oldText.length);
	}
	return out;
}

function computeChange(
	toolName: string,
	input: { path: string; edits?: { oldText: string; newText: string }[]; content?: string },
	cwd: string,
): { absPath: string; oldContent: string; newContent: string } {
	const absPath = path.isAbsolute(input.path) ? input.path : path.resolve(cwd, input.path);
	const oldContent = readExisting(absPath);

	if (toolName === "write") {
		return { absPath, oldContent, newContent: input.content ?? "" };
	}
	// edit
	const newContent = applyEditsLocally(oldContent, input.edits ?? []);
	return { absPath, oldContent, newContent };
}

// ---------------------------------------------------------------------------
// Console diff viewer
// ---------------------------------------------------------------------------

function makeDiffViewer(
	theme: Theme,
	absPath: string,
	displayDiff: string,
	done: (decision: ReviewDecision) => void,
): Component {
	const diffLines = renderDiff(displayDiff).split("\n");
	const header = [theme.fg("accent", `🔍 Review: ${absPath}`)];

	return {
		render: (width: number) => [...header, ...diffLines.map((line) => truncateToWidth(line, width))],
		handleInput: (data: string) => {
			if (matchesKey(data, "a")) {
				done("approve");
			} else if (matchesKey(data, "r") || matchesKey(data, "escape") || matchesKey(data, "ctrl+c")) {
				done("reject");
			} else if (matchesKey(data, "n")) {
				done("nvim");
			}
		},
	};
}

// ---------------------------------------------------------------------------
// Neovim viewer
// ---------------------------------------------------------------------------

function nvimAvailable(): boolean {
	try {
		return spawnSync("nvim", ["--version"], { stdio: "ignore" }).status === 0;
	} catch {
		return false;
	}
}

interface NvimFiles {
	dir: string;
	oldName: string;
	newName: string;
}

// Temp copies of old/new content. The real file is never opened or written;
// edits in the right pane only affect the temp "new" file.
function prepareNvimFiles(change: { absPath: string; oldContent: string; newContent: string }): NvimFiles {
	const ext = path.extname(change.absPath);
	const dir = fs.mkdtempSync(path.join(os.tmpdir(), "pi-review-"));
	const oldName = `old${ext}`;
	const newName = `new${ext}`;
	fs.writeFileSync(path.join(dir, oldName), change.oldContent);
	fs.writeFileSync(path.join(dir, newName), change.newContent);
	return { dir, oldName, newName };
}

async function openInNvim(ctx: ExtensionContext, files: NvimFiles): Promise<string | null> {
	if (!nvimAvailable()) {
		ctx.ui.notify("neovim not found in PATH", "error");
		return null;
	}

	// Side-by-side diff split: old content (readonly) vs new content (editable).
	// Run from the temp dir with bare file names so no path quoting is needed.
	const args = [
		files.oldName,
		"-c", `rightbelow vsplit ${files.newName}`,
		"-c", "diffthis",
		// wincmd h = move LEFT (l would move right, where there is no window).
		"-c", "wincmd h",
		"-c", "diffthis",
		// readonly is buffer-local: lock the old buffer (left) only;
		// the new buffer (right) stays editable.
		"-c", "setl readonly nomodifiable",
		"-c", "wincmd l",
		"-c", "setl noswapfile",
		"-c", `echo 'Review mode: edit the right pane, :wq to save into the diff (the real file is NOT modified until you approve)' | redraw!`,
	];

	// Suspend the TUI, hand the terminal to nvim, then restore.
	await ctx.ui.custom<number | null>((tui, _theme, _kb, done) => {
		tui.stop();
		process.stdout.write("\x1b[2J\x1b[H");
		const result = spawnSync("nvim", args, { stdio: "inherit", cwd: files.dir });
		tui.start();
		tui.requestRender(true);
		done(result.status);
		return { render: () => [], invalidate: () => {} };
	});

	// Pick up whatever the user saved in the temp "new" file.
	try {
		return fs.readFileSync(path.join(files.dir, files.newName), "utf8");
	} catch {
		return null;
	}
}

// ---------------------------------------------------------------------------
// Extension
// ---------------------------------------------------------------------------

export default function reviewModeExtension(pi: ExtensionAPI): void {
	let reviewEnabled = false;

	function updateStatus(ctx: ExtensionContext): void {
		if (reviewEnabled) {
			ctx.ui.setStatus("review-mode", ctx.ui.theme.fg("warning", "🔍 review"));
		} else {
			ctx.ui.setStatus("review-mode", undefined);
		}
	}

	function persistState(): void {
		pi.appendEntry("review-mode", { enabled: reviewEnabled } satisfies ReviewState);
	}

	function toggleReview(ctx: ExtensionContext): void {
		reviewEnabled = !reviewEnabled;
		ctx.ui.notify(
			reviewEnabled
				? "Review mode ON: every edit/write requires your approval."
				: "Review mode OFF: changes are applied without confirmation.",
			"info",
		);
		updateStatus(ctx);
		persistState();
	}

	pi.registerFlag("review", {
		description: "Start in review mode (confirm every file change)",
		type: "boolean",
		default: false,
	});

	pi.registerCommand("review", {
		description: "Toggle review mode (human approval for every edit/write)",
		handler: async (_args, ctx) => toggleReview(ctx),
	});

	// Gate file-mutating tools
	pi.on("tool_call", async (event, ctx) => {
		if (!reviewEnabled) return undefined;
		if (event.toolName !== "edit" && event.toolName !== "write") return undefined;

		const input = event.input as { path: string; edits?: { oldText: string; newText: string }[]; content?: string };

		// Fail-safe: without a UI we cannot ask, so block.
		if (!ctx.hasUI || ctx.mode !== "tui") {
			return {
				block: true,
				reason: `Review mode is active but no interactive UI is available; change to ${input.path} was blocked. Disable review mode (/review) to allow unattended changes.`,
			};
		}

		let change: { absPath: string; oldContent: string; newContent: string };
		try {
			change = computeChange(event.toolName, input, ctx.cwd);
		} catch (err) {
			return { block: true, reason: `Review mode: failed to compute diff: ${String(err)}` };
		}

		if (change.oldContent === change.newContent) {
			return undefined; // no-op change, nothing to review
		}

		let displayDiff = generateDiffString(change.oldContent, change.newContent).diff;
		const nvimFiles = prepareNvimFiles(change);

		// Review loop: the user may open neovim any number of times before deciding.
		for (;;) {
			const decision = await ctx.ui.custom<ReviewDecision>((_tui, theme, _kb, done) =>
				makeDiffViewer(theme, change.absPath, displayDiff, done),
			);

			if (decision === "approve") {
				ctx.ui.notify(`Approved: ${change.absPath}`, "success");
				return undefined;
			}
			if (decision === "reject") {
				ctx.ui.notify(`Rejected: ${change.absPath}`, "warning");
				return {
					block: true,
					reason: `User rejected this change in review mode. Do not retry the same edit; ask the user how to proceed or adjust the change.`,
				};
			}
			// decision === "nvim"
			const edited = await openInNvim(ctx, nvimFiles);
			if (edited !== null && edited !== change.newContent) {
				change.newContent = edited;
				// Rewrite the tool input in place right away, so whatever is
			// approved later is exactly what the user saved in neovim.
			if (event.toolName === "write") {
				input.content = change.newContent;
			} else {
				// Single whole-file replacement: old content -> edited content.
				input.edits = [{ oldText: change.oldContent, newText: change.newContent }];
			}
				displayDiff = generateDiffString(change.oldContent, change.newContent).diff;
				ctx.ui.notify("Diff updated with your neovim edits", "info");
			}
		}
	});

	// Restore state on session start/resume
	pi.on("session_start", async (_event, ctx) => {
		if (pi.getFlag("review") === true) {
			reviewEnabled = true;
		}

		const entries = ctx.sessionManager.getEntries();
		const stateEntry = entries
			.filter((e: { type: string; customType?: string }) => e.type === "custom" && e.customType === "review-mode")
			.pop() as { data?: ReviewState } | undefined;

		if (stateEntry?.data) {
			reviewEnabled = stateEntry.data.enabled ?? reviewEnabled;
		}

		updateStatus(ctx);
	});
}
