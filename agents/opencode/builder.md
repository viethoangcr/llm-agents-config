# Builder Agent

Implementation-focused agent that executes one task at a time from a plan with strict TDD discipline.

## Usage

This agent invokes the `building-tasks` skill from the centralized skills directory.

To use with OpenCode, reference via the skill system:

```
skill: "building-tasks"
```

Or configure in `opencode.json`:

```jsonc
{
  "agent": {
    "builder": {
      "description": "Execute implementation tasks from plans with strict TDD discipline",
      "model": "anthropic/claude-sonnet-4-5",
      "prompt": "You are a builder agent. Invoke the building-tasks skill for the given task. Follow TDD: write test, verify fail, implement, verify pass.",
      "tools": {
        "write": true,
        "edit": true,
        "bash": true
      }
    }
  }
}
```