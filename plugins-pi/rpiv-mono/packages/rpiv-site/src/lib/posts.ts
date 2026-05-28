import { type CollectionEntry, getCollection } from "astro:content";
import { computeReadingTime } from "./reading-time";

export { computeReadingTime };

export type PostEntry = CollectionEntry<"posts">;

export interface PostWithReadingTime extends PostEntry {
	readingTime: number;
}

// Shared base: published (non-draft) posts sorted newest-first. Consumed by
// the listing page (via getAllPosts), the detail page's getStaticPaths, and
// the RSS endpoint — all three must agree on what "published" means.
export async function getPublishedPosts(): Promise<PostEntry[]> {
	const posts = await getCollection("posts", ({ data }) => !data.draft);
	return posts.sort((a, b) => b.data.pubDate.valueOf() - a.data.pubDate.valueOf());
}

export async function getAllPosts(): Promise<PostWithReadingTime[]> {
	const posts = await getPublishedPosts();
	return posts.map((post) => ({
		...post,
		readingTime: computeReadingTime(post.body ?? ""),
	}));
}
