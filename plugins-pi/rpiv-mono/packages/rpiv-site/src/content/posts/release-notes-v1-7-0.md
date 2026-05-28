---
title: "Release notes: v1.7.0"
description: "rpiv-advisor learns to keep quiet around strong executor models, bundled agents move to a single global home, and the blog finally has a proper front door."
pubDate: 2026-05-15T18:00:00Z
author: juicesharp
tags: ["release", "rpiv-advisor", "rpiv-pi", "rpiv-site"]
draft: false
---

v1.7.0 shipped a day before the v1.8.0 you've already heard about. It
landed three real changes — one in the advisor, one in the pi
extension runtime, and one on this site — and a fourth made of small
polish nobody needs called out.

## rpiv-advisor: a per-executor-model blocklist

The advisor injects a tool the executor can call to ask for guidance.
That's cheap for small models — the tool is a real lifeline — but
expensive for strong ones, where the schema lives in the prompt cache,
the description lives in the system prompt, and the executor almost
never calls it. v1.7.0 lets `advisor.json` name the executor models
that should keep the advisor inactive. When the running executor
matches the blocklist, the tool isn't injected, the schema doesn't
land in the cache, and the system prompt stays smaller.

This is opt-in by name, not by capability tier. If you're running Opus
as the executor and you want the advisor available anyway, leave the
blocklist alone. The behavior change only fires when you list the
model.

## rpiv-pi: bundled agents go global

Until v1.7.0 the bundled-agent sync wrote into `<cwd>/.pi/agents/`. If
you opened pi in three different working directories you ended up
maintaining three copies of the same agent set, each one trailing
slightly behind the package version of whichever cwd you ran upgrade
in last. v1.7.0 moves the sync target to `~/.pi/agent/agents/` —
single global location, single source of truth, one upgrade reaches
every cwd.

The first session after upgrade migrates any pre-existing per-cwd
install into the global directory. The manifest write is now
crash-safe (atomic temp-file rename), so a power loss mid-sync can no
longer leave the agent set in a half-rewritten state.

There's one internal breaking change: `syncBundledAgents` no longer
takes a `cwd` argument. If you've vendored or wrapped the sync
function it'll need a one-line update; nothing else in the package
surface changed.

## rpiv-site: the blog has a front door

The blog page got the treatment that should have come with the first
post. A hero strip with the sumi-ink backdrop sits above a real page
heading instead of dropping straight into a post list. An RSS link
lives in plain sight next to the index. Posts on the index show their
author, and the same byline lands in the feed as `dc:creator` so
readers in feed clients see who wrote the piece instead of an empty
slot. Two pieces — the [skill-testing
post](/blog/how-we-test-skills/) and the [discover vs SAGE
A/B](/blog/discover-dialectic-ab/) — went up under the new layout.

The agent reference schema also gained `purpose`, `when_to_use`, and
`dispatched_by` fields, so the agent pages can explain why an agent
exists and which skill spawns it without you having to read the agent
source.

## Anything else?

The other packages in the `@juicesharp/rpiv-*` family bumped to 1.7.0
with no user-visible changes — lockstep means one number even when
only three packages have a story to tell.

Grab the new version the usual way:

```sh
npm install @juicesharp/rpiv-pi@1.7.0
```

Or let your normal upgrade flow pick it up. The full per-package
changelog lives in each package's `CHANGELOG.md` in the
[monorepo](https://github.com/juicesharp/rpiv-mono).

See you at v1.8.0 — which, as of yesterday, has already arrived.
