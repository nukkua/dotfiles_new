/**
 * rpiv-advisor — Pi extension
 *
 * Registers the `advisor` tool, `/advisor` command, and the three lifecycle
 * hooks (session_start restore, before_agent_start strip, model_select
 * re-evaluation) that together implement the advisor-strategy pattern.
 *
 * Config persists at ~/.config/rpiv-advisor/advisor.json. Tool name
 * preserved verbatim from rpiv-pi@7525a5d.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import {
	registerAdvisorBeforeAgentStart,
	registerAdvisorCommand,
	registerAdvisorTool,
	registerModelSelectHandler,
	restoreAdvisorState,
} from "./advisor.js";

export default function (pi: ExtensionAPI) {
	registerAdvisorTool(pi);
	registerAdvisorCommand(pi);
	registerAdvisorBeforeAgentStart(pi);
	registerModelSelectHandler(pi);

	pi.on("session_start", async (_event, ctx) => {
		restoreAdvisorState(ctx, pi);
	});
}
