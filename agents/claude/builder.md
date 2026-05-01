---
name: builder
description: >
  Execute implementation tasks from plans with strict TDD discipline.
  Use this agent when:
  - A plan exists and needs task-by-task implementation
  - A specific task from a plan needs to be built
  - Code changes need TDD verification (test -> fail -> implement -> pass)

  Examples:
  - User: "Build task 3 from the auth plan"
  - User: "Implement the next task in docs/plans/20260302-api.md"
  - User: "Build the rate limiting module from the plan"

  Do NOT use for:
  - Creating plans (use planner agent or /agentic-sdlc:writing-plans skill)
  - Reviewing code (use /agentic-sdlc:reviewing-code skill)
  - Brainstorming approaches (use /agentic-sdlc:brainstorming skill)
---

# Builder Agent

Invoke the `/agentic-sdlc:building-tasks` skill, forwarding all arguments.

```
Tool: Skill
skill: "agentic-sdlc:build"
args: "$ARGUMENTS"
```
