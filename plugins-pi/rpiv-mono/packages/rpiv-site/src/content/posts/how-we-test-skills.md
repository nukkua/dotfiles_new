---
title: "How we test skills at Codemasters"
description: "A small recipe for evaluating prompt changes against data instead of vibes: parallel arms, cheat-sheet answers, blinded LLM judges on a frozen rubric. The discover vs SAGE A/B is the worked example."
pubDate: 2026-05-14T22:30:00Z
author: juicesharp
tags: ["methodology", "evaluation", "prompt-engineering"]
draft: false
---

Skills are prompts, and prompts are noisy. We can't tell from the inside
whether a change made discover better, worse, or just different. So when
we ship a non-trivial skill change, we test it against the version it
replaces. The recipe is small enough to fit on a card.

## The recipe

1. **Spin up a variant skill** as a sibling of the current one. Same
   user-facing surface so an operator can't easily tell them apart at
   invocation time. The internal flow is whatever you want to test.
2. **Source a small but diverse task set**, 10 to 20 real cases,
   stratified across axes where the variant might behave differently
   (greenfield vs brownfield, narrow vs cross-cutting, simple vs vague).
3. **Lock the answers.** For each task, write a short ground-truth
   cheat-sheet the operator reads from during the interview. Same answers
   regardless of variant. Without this, the operator's improvising
   becomes a third variable.
4. **Run both arms** with randomized variant-to-task assignment so
   neither arm gets the easy half.
5. **Strip provenance** from the resulting artifacts (variant tags,
   internal annotations, anything that hints at which arm produced what)
   and replace filenames with random IDs.
6. **Hand the stripped artifacts to blind LLM judges**, ideally two
   different models, on a rubric frozen before any artifact is generated.
7. **Aggregate per-dimension and per-cell**, not just totals. The
   interesting findings live in subgroups; a variant can win on
   familiar/add-new and lose on greenfield/refactor, and the headline
   flattens that out.

## Why it works

The recipe forces evidence over preference. The operator usually
develops a gut feeling about which variant they prefer mid-run.
Sometimes the judges confirm it; sometimes they find the operator was
right about the direction but wrong about which cell mattered most.
Either way you end up with a defensible call instead of a vibes-based
one. The blinding matters more than the volume; 16 cases with clean
blinding beats 100 where the judge can guess provenance from a stylistic
tell.

## The worked example

The most recent run of this recipe was
[discover vs SAGE](/blog/discover-vs-sage/), a 16-case A/B between the
current discover skill and a variant adapted from the SAGE-Agent paper.
The variant looked promising on a single case earlier in development;
the full A/B reversed the finding. Post walks through the per-dimension
scoreboard, the W/L/D head-to-head table, and the deciding mechanism.

We do this for any non-trivial discover-tier or research-tier skill
change. It's the cheapest insurance against shipping a degradation that
sounded clever on paper.
