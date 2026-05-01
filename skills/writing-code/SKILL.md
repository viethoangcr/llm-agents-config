---
name: writing-code
description: Implements production code from a plan reference or direct instruction, producing verified results with test and lint output. Suitable for writing new features, modifying existing code, or making ad-hoc implementation changes that need evidence of correctness without full plan orchestration.
---

# Writing Code

Use this skill when you need to implement production code, either from a plan reference or from direct instruction.

## Core Principle

Evidence before claims — always verify code works before declaring it done.

## Process

1. **Understand** - Read the task or plan, understand requirements
2. **Search** - Use Glob/Grep to find existing patterns, utilities, and related code
3. **Implement** - Write minimal, focused changes following project conventions
4. **Verify** - Run relevant tests/lint, confirm output passes
5. **Report** - Summarize what was changed and verification results

## Standards

- Follow existing project patterns
- Minimal changes — edit only what's needed
- Self-documenting code through clear naming
- No unnecessary comments

## Task

$ARGUMENTS