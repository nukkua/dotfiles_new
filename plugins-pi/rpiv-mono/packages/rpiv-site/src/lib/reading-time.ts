// Pure word-count → minutes utility, factored out of `posts.ts` so it has no
// dependency on `astro:content` (an Astro virtual module that Vitest cannot
// resolve outside the Astro build). The detail page and the listing adapter
// both import from here; tests live alongside.
export function computeReadingTime(body: string): number {
	const words = body.split(/\s+/).filter(Boolean).length;
	return Math.max(1, Math.ceil(words / 200));
}
