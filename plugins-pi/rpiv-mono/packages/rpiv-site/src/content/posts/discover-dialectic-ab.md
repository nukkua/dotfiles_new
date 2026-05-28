---
title: "A sharper discover"
description: "Architectural questions in the discover skill now name what they sacrifice, not just what they choose. Decisions arrive with a real rationale instead of agreement, and scope stays on the ask you actually made."
pubDate: 2026-05-14T12:00:00Z
author: juicesharp
tags: ["discover", "prompt-engineering"]
draft: false
---

`discover` is the interview at the head of the pipeline. Its Decisions
propagate forward into `research` and `design`, so a prompt change here
travels.

We changed how it asks architectural questions. The old phrasing offered
a recommendation and a few alternatives, which the developer almost always
agreed with. The new phrasing makes each option name what it optimizes for
AND what it sacrifices. You can't pick an option without committing to a
tradeoff side. The Decision that comes out the other end carries a real
rationale instead of "agreed".

We A/B'd the change against the canonical skill across a spread of real
intake tasks. Blind judges scored both sides. The new framing won
decisively where we expected (tradeoff articulation, rationale density),
and it lost a few times in a way we didn't expect: by quietly rescoping
the request once the probe surfaced a cheaper interpretation. The
mechanism was working a little too well at "what does this option
sacrifice", and occasionally the answer was "we could sacrifice the
scope".

So we shipped both the change and three small guardrails on top: no silent
rescoping (cheaper interpretations become an explicit question to the
developer), no silent scope creep (incidental fixes go to a Suggested
Follow-ups section, not Decisions), and acceptance criteria have to name a
concrete observable behavior rather than "feature works correctly".

The net effect: Decisions arrive with their tradeoffs on the table, the
FRD stays on the ask you actually made, and downstream skills inherit a
sharper Developer Context. Same skill, same one-question-at-a-time flow,
just less rubber-stamping at the architectural layer.
