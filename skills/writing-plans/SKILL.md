---
name: writing-plans
description: Creates detailed implementation plans with builder-ready tasks, TDD steps, and verification commands. Produces self-contained task breakdowns suitable for automated execution when starting a new feature, decomposing work into testable increments, or preparing a roadmap for /agentic-sdlc:executing-plans. Triggers on requests to plan, decompose, or break down implementation work.
---

# Writing Plans

## Core Principle

A plan is self-contained: it states the goal, the specs/requirements, and the interfaces up front, so a builder agent executing its tasks needs nothing but the plan file. Every task carries the references (files, types, code locations, interface signatures) the agent needs; the plan must never force a builder to guess or go hunting. Ambiguous plans create cascading failures.

## Process

1. **Understand** — Parse the feature/request, ask clarifying questions if ambiguous
2. **Research** — Use Glob/Grep to understand current codebase structure, patterns, and related code
3. **Define** — Write the goal and explicit specs/requirements (behavior, constraints, acceptance criteria). If requirements are missing, state assumptions instead of leaving gaps. Include a **Target State** diagram (and **Current State** when it clarifies or when there's an existing implementation to change)
4. **Interface Design** — For new or updated public interfaces/modules, declare each one with its full signature: types, params, return values, error semantics. For multi-phase plans, state the high-level goal of each phase up front
5. **Decompose** — Break into ordered tasks with:
   - Clear title and description
   - Specific files to modify
   - References — the exact interfaces, types, symbols, and code locations the task depends on
   - Test-first approach (what to test before implementing)
   - Verification command (how to confirm it works)
6. **Review** — Thoroughly review the draft against the plan checklist before it goes to a builder. Verify self-containment (every task has everything it needs), correct signatures, complete diagrams, and per-phase goals
7. **Document** — Save to `docs/plans/YYYYMMDD-<slug>.md`

## Review Checklist

A plan is only ready once all of these hold:

- **Self-contained** — a builder can implement every task using only the plan file; no missing references or "figure it out" gaps
- **Goal** — states what the plan achieves in one or two sentences
- **Requirements** — every behavior, constraint, and acceptance criterion is explicit; assumptions are labelled as such
- **Diagrams** — Target State present; Current State included whenever existing code is modified (Mermaid diagrams)
- **Phase goals** — every phase in a multi-phase plan has its own high-level goal
- **Interfaces** — all new/updated public interfaces/modules include full types and method signatures
- **Tasks** — each is atomic, references exact files/symbols, has a test-first step and a verification command
- **References** — every task names the interfaces/types it relies on so the builder needs nothing else

If any check fails, revise before saving as APPROVED.

## Do / Don't

- DO keep the plan as short as possible while retaining all information
- DO break work into atomic, independently verifiable tasks
- DO include exact file paths, function names, and interface signatures
- DO specify test commands that can be run to verify each task
- DO write tasks so a builder can complete them from the plan file alone
- DO include every reference a task needs to avoid the builder searching the codebase
- DON'T create vague tasks like "improve performance"
- DON'T skip verification steps
- DON'T leave interfaces unspecified when they introduce or change public surfaces

## Impact Assessment

For each task, assess:
- **Risk**: Low (isolated change) | Medium (affects multiple files) | High (cross-system or breaking)
- **Reversibility**: Easy to revert | Needs backup | Irreversible

## Output

Read [TEMPLATES.md](TEMPLATES.md) for the plan output format before generating.

Save to `docs/plans/YYYYMMDD-<slug>.md`.
After creating the plan: summarize tasks, highlight risks, and note any open questions.

## Draft Mode (append when --draft is used)

```
## Draft Mode

Save the plan first, then ask for review.

1. Write plan to `docs/plans/YYYYMMDD-<slug>.md`
2. Display summary to user
3. Use AskUserQuestion: "I've saved the implementation plan. What would you like to do?"
   - Options: "Approve plan", "Revise plan", "Delete plan"

Handle: Approve → ready for /agentic-sdlc:executing-plans | Revise → update file | Delete → remove
```

After completion, share plan location and task summary.
