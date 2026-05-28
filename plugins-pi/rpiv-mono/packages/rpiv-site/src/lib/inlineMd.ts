/** Render a tiny subset of inline Markdown (`` `code` `` + `**bold**`) so frontmatter
 *  strings that contain code spans match the look of the surrounding prose.
 *  HTML-escapes the rest of the input — never bypass without escaping.
 *
 *  Consumers: `pages/docs/reference/skills/[slug].astro`,
 *             `pages/docs/reference/agents/[slug].astro`. */
export function inlineMd(input: string | undefined): string {
	if (!input) return "";
	const escaped = input.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
	return escaped.replace(/`([^`]+)`/g, "<code>$1</code>").replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>");
}
