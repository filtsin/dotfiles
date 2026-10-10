/**
 * Auto-Compact Toggle Extension
 *
 * Session-scoped toggle for automatic compaction (does NOT touch global
 * settings, so other sessions are unaffected).
 *
 * - `/auto-compact`      — toggle (default: enabled)
 * - `/auto-compact on`   — enable
 * - `/auto-compact off`  — disable
 *
 * While disabled, automatic compaction (context threshold and overflow
 * recovery) is cancelled. Manual `/compact` still works.
 *
 * State is persisted in the session file via a custom entry, so it survives
 * /tree navigation and session resume, and follows the active branch.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const ENTRY_TYPE = "auto-compact";

export default function (pi: ExtensionAPI) {
	// Default: auto-compaction enabled. Restored on session_start.
	let enabled = true;

	pi.on("session_start", (_event, ctx) => {
		enabled = true;
		const entries = ctx.sessionManager.getBranch();
		for (let i = entries.length - 1; i >= 0; i--) {
			const entry = entries[i];
			if (entry.type === "custom" && entry.customType === ENTRY_TYPE) {
				const data = entry.data as { enabled?: boolean } | undefined;
				if (typeof data?.enabled === "boolean") {
					enabled = data.enabled;
				}
				break;
			}
		}
	});

	pi.on("session_before_compact", (event, _ctx) => {
		// Only intercept automatic compaction; manual /compact always works.
		if (!enabled && event.reason !== "manual") {
			return { cancel: true };
		}
	});

	pi.registerCommand("auto-compact", {
		description: "Toggle auto-compaction for this session (on/off)",
		handler: async (args, ctx) => {
			const arg = args.trim().toLowerCase();
			let next: boolean;
			if (arg === "on") next = true;
			else if (arg === "off") next = false;
			else next = !enabled;

			enabled = next;
			pi.appendEntry(ENTRY_TYPE, { enabled });
			ctx.ui.notify(`Auto-compaction ${next ? "enabled" : "disabled"} for this session`, "info");
		},
	});
}
