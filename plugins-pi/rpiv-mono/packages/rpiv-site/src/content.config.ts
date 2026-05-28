import { defineCollection, z } from "astro:content";
import { glob } from "astro/loaders";

const skillSpecs = defineCollection({
	loader: glob({ pattern: "*/SKILL.md", base: "../rpiv-pi/skills" }),
	schema: z.object({
		name: z.string(),
		description: z.string(),
		"argument-hint": z.union([z.string(), z.array(z.string())]).optional(),
		"allowed-tools": z.union([z.string(), z.array(z.string())]).optional(),
		"disable-model-invocation": z.boolean().optional(),
	}),
});

const skills = defineCollection({
	loader: glob({ pattern: "*.md", base: "./src/content/skills" }),
	schema: z.object({
		slug: z.string(),
		tagline: z.string(),
		/** Why this skill exists. 1–2 sentences. Markdown allowed. */
		purpose: z.string().optional(),
		/** Bulleted triggers + skip conditions. */
		when_to_use: z.array(z.string()).optional(),
		/** Required/optional inputs the skill consumes. */
		inputs: z
			.array(
				z.object({
					name: z.string(),
					required: z.boolean().default(false),
					source: z.string().optional(),
					notes: z.string().optional(),
				}),
			)
			.optional(),
		/** Artifacts the skill writes. */
		outputs: z
			.array(
				z.object({
					artifact: z.string(),
					path: z.string().optional(),
					format: z.string().optional(),
				}),
			)
			.optional(),
		/** Ordered procedure with rationale per step. */
		key_steps: z
			.array(
				z.object({
					title: z.string(),
					rationale: z.string(),
				}),
			)
			.optional(),
		/** Upstream feeders and downstream consumers (skill slugs). */
		related: z
			.object({
				upstream: z.array(z.string()).default([]),
				downstream: z.array(z.string()).default([]),
			})
			.optional(),
	}),
});

const agentSpecs = defineCollection({
	loader: glob({ pattern: "*.md", base: "../rpiv-pi/agents" }),
	schema: z.object({
		name: z.string(),
		description: z.string(),
		tools: z.string().optional(),
		isolated: z.boolean().optional(),
	}),
});

const agents = defineCollection({
	loader: glob({ pattern: "*.md", base: "./src/content/agents" }),
	schema: z.object({
		slug: z.string(),
		tagline: z.string(),
		/** Why this agent exists. 1–2 sentences. Markdown allowed. */
		purpose: z.string().optional(),
		/** Single-sentence trigger statement. Markdown allowed.
		 *  Scalar (not array) — rendered as a single <p>, not a <ul>. */
		when_to_use: z.string().optional(),
		/** Skill slugs (in `src/content/skills/*.md`) that dispatch this agent.
		 *  Flat array — dispatch is one-directional, no upstream/downstream split. */
		dispatched_by: z.array(z.string()).optional(),
	}),
});

const extensions = defineCollection({
	loader: glob({ pattern: "*.md", base: "./src/content/extensions" }),
	schema: z.object({
		slug: z.string(),
		tagline: z.string(),
		package: z.string(),
		status: z.enum(["stable", "beta", "experimental"]).default("stable"),
		order: z.number().default(0),
	}),
});

const posts = defineCollection({
	loader: glob({ pattern: "*.md", base: "./src/content/posts" }),
	schema: z.object({
		title: z.string(),
		description: z.string(),
		pubDate: z.coerce.date(),
		updatedDate: z.coerce.date().optional(),
		author: z.string().default("juicesharp"),
		tags: z.array(z.string()).default([]),
		draft: z.boolean().default(false),
	}),
});

const docs = defineCollection({
	loader: glob({ pattern: "**/*.md", base: "./src/content/docs" }),
	schema: z.object({
		title: z.string(),
		description: z.string().optional(),
		section: z.enum(["getting-started", "guides", "explanation", "reference"]),
		order: z.number().default(0),
		draft: z.boolean().default(false),
	}),
});

export const collections = { skills, skillSpecs, agents, agentSpecs, extensions, posts, docs };
