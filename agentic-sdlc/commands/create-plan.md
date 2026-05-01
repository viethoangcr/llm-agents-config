---
name: create-plan
description: Quick command to create an implementation plan (shortcut for /agentic-sdlc:writing-plans --draft)
argument-hint: "<task> [--brainstorm <path>] [custom instructions...]"
---

Create a detailed implementation plan for the given task. Save as draft for review before execution.

## Parse Arguments

Parse the following known flags from `$ARGUMENTS`:

| Flag | Default | Description |
|------|---------|-------------|
| `--brainstorm <path>` | none | Path to brainstorm output to use as input |
| `--draft` | always on | Save as draft (always applied by this command) |

**Custom instructions:** Any text in `$ARGUMENTS` that does not match a known flag or its value is treated as a combination of the task description and custom instructions. The first natural phrase is the task; any additional directives are custom instructions.

Examples:
- `/create-plan Add user auth` → task=`Add user auth`, no custom instructions
- `/create-plan Add user auth use JWT and Redis for sessions` → task=`Add user auth`, custom instructions=`use JWT and Redis for sessions`
- `/create-plan Add caching --brainstorm docs/brainstorm.md prefer Redis over Memcached` → task=`Add caching`, brainstorm=`docs/brainstorm.md`, custom instructions=`prefer Redis over Memcached`

If no arguments provided, ask what feature or task needs planning.

## Instructions

Invoke the `/agentic-sdlc:writing-plans` skill with `--draft` and all parsed flags. If custom instructions were parsed, append them with `--instructions`:

```
Tool: Skill
skill: "agentic-sdlc:plan"
args: "--draft <task> <parsed flags> --instructions <custom instructions>"
```

If no custom instructions, forward only the task and parsed flags:

```
Tool: Skill
skill: "agentic-sdlc:plan"
args: "--draft $ARGUMENTS"
```
