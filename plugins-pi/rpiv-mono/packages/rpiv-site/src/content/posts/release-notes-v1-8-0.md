---
title: "Release notes: v1.8.0"
description: "rpiv-web-tools learns five new search engines, /web-search-config gets a friendlier picker, raw fetch refuses to talk to your localhost, and the web-search-researcher stops hiding in its own room."
pubDate: 2026-05-16T15:00:00Z
author: juicesharp
tags: ["release", "rpiv-web-tools", "rpiv-pi"]
draft: false
---

The headline of v1.8.0 is `rpiv-web-tools`. For a year it spoke one
search engine — Brave — and that was the whole story. v1.8.0 turns it
into a multi-provider tool: Brave, Tavily, Serper, Exa, Jina, and
Firecrawl all sit behind the same interface, and you pick the one you
want with `/web-search-config`.

## rpiv-web-tools: six providers, one tool

Each vendor now lives in its own `providers/<name>.ts` behind a stable
`SearchProvider` contract. Brave and Serper keep the existing
HTTP-plus-`htmlToText` pipeline through `providers/fetch-helpers.ts`,
the way `web_fetch` always worked. Tavily, Exa, Jina, and Firecrawl
plug into their native extraction endpoints instead — Jina via
`r.jina.ai`, Firecrawl via `/v1/scrape`, and so on — so the fetch you
get back is the one the vendor designed, not a generic HTML scrape.

API keys are now resolved per-provider: each vendor reads its own
environment variable (`TAVILY_API_KEY`, `EXA_API_KEY`, etc.) and falls
back to its own config slot. The legacy top-level `apiKey` field is
still honored for Brave, and gets migrated lazily on the next save, so
nobody has to touch their config file to upgrade.

## `/web-search-config` got friendlier

The picker used to be an alphabetical list of provider names. It now
opens with the active provider on top marked with a ✓, every provider
that has a key saved tagged `(configured)`, and the rest below. When
the input prompt asks for a key, it shows the masked current value;
submitting empty preserves what you had and still switches the active
provider. So changing engines no longer means re-typing the key you
already entered.

A small follow-up cleaned up the labels: notifications and input
titles now show the bare provider name instead of the picker
ornaments, and the active-provider matcher uses a prefix match rather
than a regex-strip, which means future label markers won't break the
selection logic.

## Raw fetch refuses your localhost

Brave and Serper go through `parseAndAssertHttpUrl` before they hit
the network. The check now rejects loopback (`localhost`, `127/8`,
`::1`), private RFC1918 ranges (`10/8`, `172.16-31/12`, `192.168/16`),
link-local (`169.254/16`, `fe80::/10`), and unique-local IPv6
(`fc00::/7`). The motivation is SSRF: a search result URL that
resolves to your dev server or the cloud metadata endpoint shouldn't
get fetched through the agent. Jina, Firecrawl, Tavily, and Exa go
through their own vendor endpoints and weren't affected.

There's also one small contract fix in `providers/jina.ts`: an empty
response body now throws the same way Tavily, Exa, and Firecrawl have
always thrown, instead of returning a quiet empty string downstream.

## web-search-researcher loses its `isolated` flag

The `web-search-researcher` agent that ships with `rpiv-pi` used to
run with `isolated: true` in its frontmatter, which gave it a fresh
context on every invocation. v1.8.0 removes that flag. The researcher
now shares context with the calling session, so when you spawn it for
a follow-up question it already knows what the conversation has been
about and won't ask you to restate the topic.

If you depended on the isolation guarantee — say, to keep a long
research chain from accumulating drift — that contract has changed.
The trade was deliberate: in real use the missing-context cost of a
cold researcher showed up more often than the drift cost of a warm
one.

## Anything else?

Every other package in the `@juicesharp/rpiv-*` family bumped to 1.8.0
with no user-visible changes. The marketing-site infographic now
reflects the six-provider story, and a few READMEs got a refresh, but
that's the lot.

Grab the new version the usual way:

```sh
npm install @juicesharp/rpiv-pi@1.8.0
```

Or let your normal upgrade flow pick it up. The full per-package
changelog lives in each package's `CHANGELOG.md` in the
[monorepo](https://github.com/juicesharp/rpiv-mono).

See you at v1.9.0.
