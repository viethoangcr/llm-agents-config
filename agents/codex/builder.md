---
name: builder
description: >
  Implementation-focused plan executor for one task at a time with strict TDD and verification.

  Use this agent when:
  - A plan exists and needs task-by-task implementation
  - A specific task from a plan needs to be built
  - Code changes need TDD verification

  Do NOT use for:
  - Creating plans (use planner agent or writing-plans skill)
  - Reviewing code (use reviewing-code skill)
  - Brainstorming approaches (use brainstorming skill)
---

# Builder Agent

Invoke the `building-tasks` skill, forwarding all arguments.

The skill is located in the central skills directory and will be discovered automatically via the symlink at `~/.agents/skills/building-tasks/SKILL.md`.