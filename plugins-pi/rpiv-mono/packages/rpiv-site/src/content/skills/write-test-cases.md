---
slug: write-test-cases
tagline: Generates flow-based manual test cases for one feature by analyzing implementing code in parallel — emits the feature suite plus a regression suite and a project-wide coverage map.
purpose: |
  The authoring half of the test-cases pair. Reads the feature's `_meta.md` (when available) as warm-start context, dispatches per-layer locator agents, and writes flow-based test specs QA can run by hand. Updates the project-wide coverage map so duplicates are avoided.
when_to_use:
  - You have an `outline-test-cases` `_meta.md` and want the suite written.
  - You want manual test cases for a single feature without scaffolding the whole project first.
  - Skip when no feature scope is known — run `outline-test-cases` first.
inputs:
  - name: feature identifier
    required: true
    source: One of `Feature Name` / `<component path>` / `feature-slug` / `_meta.md` path
  - name: additional instructions
    required: false
    source: Free-text appended after the feature identifier — passed verbatim to agents and the checkpoint
outputs:
  - artifact: Feature test cases
    path: .rpiv/test-cases/<feature>/
    format: markdown per flow
  - artifact: Regression suite
    path: .rpiv/test-cases/<feature>/_regression-suite.md
    format: markdown
  - artifact: Project coverage map
    path: .rpiv/test-cases/_coverage-map.md
    format: markdown index
key_steps:
  - title: Warm-start from `_meta.md` when present
    rationale: A pre-existing outline contributes routes, endpoints, scope decisions, and checkpoint history — agents validate it (confirmed · removed · new) rather than rediscovering from scratch.
  - title: Detect technology stack
    rationale: Framework detection (`package.json`, `.csproj`, `pyproject.toml`) tunes agent prompts so the right entry-point shapes are searched first.
  - title: Parallel feature-code discovery — Web Layer · Domain Layer · existing tests
    rationale: One `codebase-locator` per layer, plus `test-case-locator` to dedupe against prior suites. Concurrent dispatch keeps the discovery wave short.
  - title: Synthesize flows, edge cases, and a regression suite
    rationale: Flows are scenario-shaped (not file-shaped) so QA reads them like user stories. Edge cases are extracted alongside; regression items are the cross-feature ones worth keeping in the always-run set.
  - title: Update the project-wide coverage map
    rationale: A root `_coverage-map.md` is regenerated from every feature's `_regression-suite.md` so duplicates and gaps are visible at the project level — not buried per-folder.
related:
  upstream: [outline-test-cases]
  downstream: []
---
