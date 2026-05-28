import rss from "@astrojs/rss";
import type { APIContext } from "astro";
import { getPublishedPosts } from "../../lib/posts";

export async function GET(context: APIContext) {
	if (!context.site) {
		throw new Error("`site` must be configured in astro.config.mjs to generate the RSS feed.");
	}

	const posts = await getPublishedPosts();

	return rss({
		title: "rpiv-pi Blog",
		description: "Updates, deep dives, and release notes for rpiv-pi.",
		site: context.site,
		xmlns: {
			atom: "http://www.w3.org/2005/Atom",
			dc: "http://purl.org/dc/elements/1.1/",
		},
		items: posts.map((post) => {
			const extras = [
				`<dc:creator><![CDATA[${post.data.author}]]></dc:creator>`,
				post.data.updatedDate ? `<atom:updated>${post.data.updatedDate.toISOString()}</atom:updated>` : "",
			]
				.filter(Boolean)
				.join("");
			return {
				title: post.data.title,
				pubDate: post.data.pubDate,
				description: post.data.description,
				link: `/blog/${post.id}`,
				customData: extras,
			};
		}),
		customData: `<language>en-us</language>`,
	});
}
