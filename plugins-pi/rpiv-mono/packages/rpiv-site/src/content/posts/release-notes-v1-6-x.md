---
title: "Release notes: v1.6.0 and v1.6.1"
description: "A sharper discover ships as v1.6.0, and v1.6.1 follows up with a fix so the advisor stops replaying stale history after Pi compacts a session."
pubDate: 2026-05-14T22:00:00Z
author: juicesharp
tags: ["release", "rpiv-pi", "rpiv-advisor"]
draft: false
---

The 1.6 cycle landed two versions on the same day. v1.6.0 carries the
discover skill change we wrote about earlier this week; v1.6.1 is a
follow-up fix to the advisor that surfaced once 1.6.0 was in real use.

## rpiv-pi: a sharper discover (1.6.0)

The architectural questions in the discover skill now name what each
option sacrifices, not just what it optimizes for. Decisions arrive with
a real rationale instead of agreement, and the FRD stays on the ask you
actually made. Three small guardrails come with the change: cheaper
interpretations surfaced by the probe become an explicit question rather
than a silent rescope, incidental fixes go to a new Suggested Follow-ups
section instead of into Decisions, and acceptance criteria have to name
a concrete observable behavior.

The framing change was motivated by two papers: Chang's
[Socratic prompting](https://arxiv.org/abs/2303.08769) (arXiv:2303.08769)
and [Active Task Disambiguation](https://arxiv.org/abs/2502.04485)
(arXiv:2502.04485, ICLR 2025). Both argue, from different angles, that
clarification questions are most useful when they force a commitment to a
side of a real tension rather than soliciting agreement with a leading
recommendation.

The full story (including the blind 10-task A/B we ran against the
canonical skill, 3 parallel Opus judges, 7-criterion rubric) is in
[a sharper discover](/blog/discover-dialectic-ab/).

## rpiv-advisor: honoring compacted sessions (1.6.1)

When Pi compacts a long session, it replaces the conversation history
with a resolved summary plus the most recent turns. The advisor was
escalating off the pre-compaction history, which meant a session that
had just been compacted would replay stale signals into the next
escalation. v1.6.1 routes the advisor through Pi's resolved session
context, so the escalation now sees the same view of the conversation
that everything else downstream of compaction sees.

This is a behind-the-scenes fix. If you've never noticed the advisor
behaving oddly after long sessions, you weren't supposed to.

## Anything else?

Every other package in the `@juicesharp/rpiv-*` family bumped to 1.6.0
and again to 1.6.1 with no user-visible changes. Lockstep means one
number, one install, one release; it also means everything moves
together when one thing moves.

Grab the new version the usual way:

```sh
npm install @juicesharp/rpiv-pi@1.6.1
```

Or let your normal upgrade flow pick it up. The full per-package
changelog lives in each package's `CHANGELOG.md` in the
[monorepo](https://github.com/juicesharp/rpiv-mono).

See you at v1.7.0.
