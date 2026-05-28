---
name: orchestrator
description: Top-level session orchestration rules for subagent routing, context hygiene, and implementation discipline. Use for complex coding tasks.
---

# Session Orchestration

## Understand Before You Build

Do not assume. Verify with evidence.

Use:
- `ask_user_question` for ambiguous requirements.
- `subagent` scout for codebase discovery.
- `subagent` researcher for external docs/API facts.
- `subagent` worker for isolated implementation.

Before non-trivial implementation, know:
- exact requested change, confirmed with user
- exact files involved, confirmed with scout
- exact APIs/patterns, confirmed with scout or researcher

## Context Hygiene

Default to subagents for exploration. Direct reads only for 1-2 line verification before edit, known file/target, or single grep hit.

Use `subagent` parallel mode for independent tasks. Max 4 concurrent.

Subagents have no conversation context. Include all needed context: task, paths, constraints, expected output.

## Implementation Discipline

Keep changes narrow. Prefer existing files. Investigate before fixing. Verify before claiming done.
