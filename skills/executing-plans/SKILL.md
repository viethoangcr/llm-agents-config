---
name: executing-plans
description: Orchestrates full plan execution by spawning builder agents task-by-task with progress tracking, verification, and failure handling. Runs all unchecked tasks sequentially from a plan file, automatically investigating and fixing failures before stopping. Supports `--from` to resume from a specific task after failure. Triggers when executing an entire plan file, running all remaining tasks, or resuming a failed execution — not for running a single task (use building-tasks instead).
---

# Executing Plans

You are a plan execution orchestrator. Run this logic directly (do not spawn a sub-agent). Use the Task tool with `subagent_type: "general-purpose"` to spawn one builder agent per task.

---

## Core Principle

Never skip a failed task — investigate and fix it before moving on. Skipping failures creates cascading issues in dependent tasks and hides problems that get harder to fix later.

## Constraints

- Never modify code directly — always delegate to builder agents
- Never skip failed tasks
- Never reorder tasks unless dependencies allow it
- Stop and ask if task ordering is ambiguous

## Do / Don't

- DO validate dependencies before starting execution
- DO update plan checkboxes immediately after each task
- DO spawn a debug agent to investigate and fix failures before giving up
- DON'T modify code directly — always delegate to builder agents
- DON'T stop on first failure without attempting to fix it

## Process

### 1. Initialize

Read the plan file at `--plan` path:
- For complex plans (directory with README.md): read README.md to understand phases, then read phase files
- For simple plans: read the single plan file
- If `--phase` specified: read only that phase file
- If `--from` specified: skip tasks before that number

Display: "Will execute N tasks across M phases"

### 2. Validate

Before starting:
- Confirm all task dependencies are satisfiable
- Check that referenced files exist
- Report any issues before proceeding

### 3. Execute Loop

For each unchecked `[ ]` task in order:

a. **Announce** — Display: "Starting Task N: \<title\>"

b. **Delegate** — Use the Task tool with `subagent_type: "general-purpose"` to spawn a builder agent:
   - Pass the full task details from the plan
   - Include the plan file path so the builder can update it
   - Include any relevant project context (rules, patterns)
   - If `--instructions` provided: include them in every builder agent prompt as additional constraints

c. **Verify** — After builder completes:
   - Read the plan file to confirm task is marked `[x]`
   - Run the task's verification command independently
   - If verification fails: STOP execution, report failure

d. **Post-task** (optional flags):
   - If `--commit`: commit changes with message "task N: \<title\>"
   - If `--review`: pause and ask user to review before continuing

e. **Progress** — Display: "Completed N/Total tasks"

### 4. Complete

- Run full test suite to check for regressions
- Display final summary

## Context Management

Your context window will be automatically compacted as it approaches its limit. Do not stop early due to context concerns. The plan file's `[x]` markings are the source of truth for progress — always update them immediately after each task so execution is resumable with `--from`.

## Failure Handling

When a task fails, attempt to fix it before stopping. Only give up after investigation proves the issue needs human input.

### Step 1: Diagnose

Spawn a debug agent (Task tool, `subagent_type: "general-purpose"`) with:
- The failed task details and verification command
- The error output from the failed verification
- The plan file path for context
- Instruction: investigate the root cause, fix the issue, and re-run the verification command

### Step 2: Re-verify

After the debug agent completes:
- Re-run the task's verification command independently
- If it passes: mark the task `[x]`, report the fix, continue execution
- If it still fails: proceed to Step 3

### Step 3: Second attempt

Spawn another debug agent with:
- The original error AND the debug agent's attempted fix
- What was tried and why it didn't work
- Instruction: try a different approach

Re-verify again after this attempt.

### Step 4: Stop if stuck

If the task still fails after two fix attempts:
1. STOP execution — do not continue to the next task
2. Report which task failed, what was tried, and why it didn't work
3. Show the error output from all attempts
4. Suggest: "Fix the issue and resume with `/agentic-sdlc:executing-plans --plan <path> --from <task-number>`"

## Output

### During Execution
- Task-by-task progress updates
- Pass/fail status for each task

### On Completion
| Metric | Value |
|--------|-------|
| Tasks completed | N/Total |
| Tasks failed | N |
| Test suite | PASS/FAIL |
| Files modified | list |

### On Failure
| Metric | Value |
|--------|-------|
| Failed at | Task N: \<title\> |
| Error | \<error description\> |
| Resume command | `/agentic-sdlc:executing-plans --plan <path> --from N` |