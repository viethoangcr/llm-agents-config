---
name: execute-plan
description: Quick command to execute a plan file using the /agentic-sdlc:executing-plans skill
argument-hint: "<plan-path> [--review] [--commit] [--phase <N>] [--from <task>] [custom instructions...]"
---

Execute an implementation plan by invoking the `/agentic-sdlc:executing-plans` skill.

## Parse Arguments

Parse the following known flags from `$ARGUMENTS`:

| Flag | Default | Description |
|------|---------|-------------|
| `--plan <path>` | first positional arg | Path to the plan file |
| `--review` | off | Pause for user review after each task |
| `--commit` | off | Auto-commit changes after each task completion |
| `--phase <N>` | all | Execute only phase N |
| `--from <task>` | 1 | Resume from task number |

**Custom instructions:** Any text in `$ARGUMENTS` that does not match a known flag or its value is treated as custom instructions. Collect all such remaining tokens into a single string.

Examples:
- `/execute-plan docs/plans/auth.md --review skip tests for now` → plan=`docs/plans/auth.md`, review=on, custom instructions=`skip tests for now`
- `/execute-plan --plan docs/plans/api.md use python 3.12 and poetry` → plan=`docs/plans/api.md`, custom instructions=`use python 3.12 and poetry`
- `/execute-plan docs/plans/cache.md` → plan=`docs/plans/cache.md`, no custom instructions

If no plan path provided, look for plan files in `docs/plans/` and ask which one to execute.

## Instructions

Invoke the `/agentic-sdlc:executing-plans` skill, forwarding all parsed flags. If custom instructions were parsed, append them with `--instructions`:

```
Tool: Skill
skill: "agentic-sdlc:execute"
args: "<parsed flags> --instructions <custom instructions>"
```

If no custom instructions, forward only the parsed flags:

```
Tool: Skill
skill: "agentic-sdlc:execute"
args: "$ARGUMENTS"
```
