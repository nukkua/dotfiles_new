---
title: "discover holds against SAGE"
description: "Why the current discover skill is good, and what blind judges said when we A/B'd it against a SAGE-Agent adaptation."
pubDate: 2026-05-14T20:00:00Z
author: juicesharp
tags: ["discover", "prompt-engineering", "evaluation"]
draft: false
---

`discover` is good because it asks coverage questions. Soft intent framing,
multi-select scope sweeps, named alternatives in non-goals. Half of those
questions have no downstream parser; they exist for the operator's own
framing. They're what keep the FRD on the ask you actually made.

We A/B'd it against an adaptation of SAGE-Agent (arXiv 2511.08798), which
replaces the question tree with EVPI scoring over a small candidate set
and a principled stop signal. 16 cases stratified across task type ×
codebase familiarity, two blind LLM judges (Opus + Sonnet), pre-registered
7-dimension rubric. Inter-judge Pearson 0.696, exact-match 81%, within-one
100%.

Scores (joint, mean across both judges, out of 21). The W/L/D column is
the variant's head-to-head record against discover across all 64
pair-comparisons per dimension (8 FRDs × 8 FRDs):

| Dimension          | discover | SAGE variant | variant vs discover W/L/D | Effect      |
|--------------------|---------:|-------------:|---------------------------|-------------|
| D1 Completeness    |     3.00 |         2.75 | 0 / 24 / 40               | medium      |
| D2 Specificity     |     2.88 |         2.69 | 6 / 21 / 37               | small       |
| D3 No-impl-leak    |     2.38 |         2.56 | 31 / 16 / 17              | small (variant) |
| D4 Anti-rescoping  |     2.81 |         2.00 | **2 / 51 / 11**           | **large**   |
| D5 Consistency     |     2.94 |         2.94 | 7 / 7 / 50                | tie         |
| D6 Auditability    |     2.56 |         2.19 | 15 / 33 / 16              | small       |
| D7 Actionability   |     2.69 |         2.44 | 16 / 29 / 19              | small       |
| **Total**          | **19.26**|    **17.57** | 77 / 181 / 190 of 448     | discover +1.69 |

Six dimensions favor `discover`, one ties, one (D3) favors the variant.
The deciding dimension is D4, anti-rescoping discipline, by a large
effect. EVPI's turn-saving mechanism skips exactly the comprehensive
scope-coverage sweeps that drive D4. Optimizing for "smallest question
set to disambiguate intent" turns out to be the wrong objective when the
artifact is a requirements document; the right objective is "did we
consider what I'm leaving out?"

We're keeping `discover`. The variant's candidate-shape framing and
Belief Trace audit block are worth porting back as a smaller change,
without the EVPI scoring that suppressed the sweeps in the first place.
