---
slug: outline-test-cases
tagline: Discovers testable features (Frontend-First) and lays out a per-feature folder under `.rpiv/test-cases/` with `_meta.md` scope decisions — ready for `write-test-cases` to fill in.
purpose: |
  Maps the project's testable surface before any test cases are authored. `outline-test-cases` discovers routes, endpoints, and existing tests, then emits a folder skeleton (one folder per feature) with metadata so `write-test-cases` can pick up scope-aware. Re-runs are incremental — prior outlines guide smarter checkpoints.
when_to_use:
  - You're starting test-case authoring for a project and need the full feature inventory.
  - An existing outline is stale and you want a diff-based refresh.
  - Skip when you only need test cases for a single feature you've already scoped.
inputs:
  - name: target-directory
    required: false
    source: CLI argument or current working directory
  - name: existing `.rpiv/test-cases/` outline
    required: false
    source: Auto-detected — triggers Incremental mode when present
outputs:
  - artifact: Per-feature outline folders
    path: .rpiv/test-cases/<feature>/_meta.md
    format: markdown with scope decisions + routes + endpoints
  - artifact: Project summary
    path: .rpiv/test-cases/README.md
    format: markdown
key_steps:
  - title: Detect Fresh vs Incremental mode
    rationale: An existing outline isn't ignored — it seeds the next run. Incremental mode highlights what changed since the last outline, so re-runs aren't wholesale rewrites.
  - title: Parallel discovery — routes · frontend HTTP call sites · backend controllers · existing test cases
    rationale: Four `codebase-locator` / `test-case-locator` agents run concurrently. Frontend-First means routes drive the feature list; backend controllers and HTTP call sites are evidence, not the starting point.
  - title: Cross-reference findings into a feature list
    rationale: Frontend routes are validated against the navigation menu, enriched via API call mapping, and cross-checked against backend controllers. Catches features the team navigates to but no backend serves (or vice versa).
  - title: Diff-based checkpoint (Incremental mode only)
    rationale: Shows added/removed features against the last outline, so the developer signs off only on the delta — not the entire list every time.
  - title: Write per-feature `_meta.md` + project README
    rationale: Each feature gets its own folder with metadata `write-test-cases` reads as warm-start context. The project README is the index — newcomers and `write-test-cases` runs both consult it.
related:
  upstream: []
  downstream: [write-test-cases]
---
