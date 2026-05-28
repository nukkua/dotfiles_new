---
title: "Release notes: v1.5.0"
description: "A redesigned voice equalizer, a sharper blueprint verifier, and a freshly minted blog, all in lockstep across the rpiv-pi family."
pubDate: 2026-05-12T12:00:00Z
author: juicesharp
tags: ["release", "rpiv-pi", "rpiv-voice"]
draft: false
---

Every package in the `@juicesharp/rpiv-*` family ships from a single tag, so
release notes are necessarily a tour. v1.5.0 is a small one (three packages
moved, the rest came along for the ride), but each of the three moved in a
direction worth a few paragraphs.

## rpiv-voice: a bell instead of bars

The voice overlay's equalizer has been redesigned. The old layout was a row of
ASCII bars driven straight off the FFT: readable, but a bit anonymous. The new
visualization arranges the bins as a centered bell silhouette, with a truecolor
accent gradient and an audio-driven animation that responds to amplitude rather
than just frequency.

It's still rendering in the terminal (no GPU, no canvas, just glyphs and ANSI
truecolor), so the silhouette has to be carved out of half-blocks and a careful
column layout. The result feels less like a meter and more like a thing that
is listening.

## rpiv-pi: a dedicated verifier for the blueprint skill

The `blueprint` skill now uses a dedicated adversarial verifier for the
per-slice micro-checkpoints. Previously the per-slice gate piggy-backed on the
same agent that did the slice itself, which made it too easy to wave through
its own work. The new verifier is its own agent, runs with its own instructions,
and is told that the slice's job is to look correct, and its job is to find
the corner where it isn't.

While the verifier got carved out, the long-standing `plan-reviewer` agent was
renamed to `artifact-reviewer`. The name was always a little narrow: in
practice the agent reviews any phased artifact (plans, designs, research
documents), and the new name reflects that. If you call this agent directly
from a skill or your own glue code, the rename is breaking. If you only go
through the bundled skills, you won't notice.

Two fixes also landed in `rpiv-pi`:

- The `web-search-researcher` agent now runs with a fresh context on each
  invocation, so a long parent session can't quietly bias a follow-up search.
- The blueprint slice verifier now receives the current slice's code in its
  dispatch payload, which fixes a class of false-positive "this slice is empty"
  violations that surfaced on cross-slice work.

## rpiv-site: the blog you're reading

This is the first release where `rpiv-site` ships a blog section at all. The
navigation has been restructured into a two-tier grid with a grouped cluster
of utility links, the listing and detail pages have serif prose typography,
and there's an RSS feed at [`/blog/rss.xml`](/blog/rss.xml) for anyone who'd
rather subscribe than visit.

The site is still private (it isn't published to npm; it deploys to GitHub
Pages as a static build), but it shares the same version and the same
release cadence as the published packages, which keeps the story tidy: when
the version bumps, the docs bump.

## Anything else?

The other workspaces (`rpiv-advisor`, `rpiv-args`, `rpiv-ask-user-question`,
`rpiv-btw`, `rpiv-i18n`, `rpiv-todo`, `rpiv-warp`, `rpiv-web-tools`) bumped
to 1.5.0 with no user-visible changes. That's the price of lockstep, and
also its point: one number, one install, one release.

You can grab the new version the usual way:

```sh
npm install @juicesharp/rpiv-pi@1.5.0
```

Or, if you already have it installed, your normal upgrade flow will pick it
up. The full per-package changelog lives in each package's `CHANGELOG.md`
in the [monorepo](https://github.com/juicesharp/rpiv-mono).

See you at v1.6.0.
