# Repository Instructions

## Purpose
- This is a central config repo for OpenCode, Claude Code, and Codex agent instructions, skills, agents, and MCP templates.
- There is no package manifest or test runner here; the main verification is reading affected markdown/config plus `bash setup.sh` when symlink behavior changes.

## Key Files
- `context/AGENTS.md` is the shared global instruction source symlinked into tool config dirs; keep it tool-agnostic.
- `skills/*/SKILL.md` is the single source of truth for skills used by all tools.
- `agents/claude/`, `agents/codex/`, and `agents/opencode/` hold tool-specific agent definitions because their formats differ.
- `mcp/` files are reference templates only; users copy relevant sections into their real tool configs.
- `agentic-sdlc/` is Claude plugin compatibility: `commands/` contains slash commands, `.claude-plugin/plugin.json` has plugin metadata, and `agents/`/`skills/` mirror the central definitions.

## Setup And Verification
- Run `bash setup.sh` from the repo root to create or refresh symlinks.
- `setup.sh` is intentionally non-destructive: it skips existing non-symlink files and never deletes old duplicates.
- When adding a skill, create `skills/<name>/SKILL.md`, then update any tool-specific docs/config snippets that mention the available skills.
- If changing symlink targets or setup output, verify `setup.sh` still links OpenCode, Claude Code, Codex, and the `agentic-sdlc` namespaced skill paths. For OpenCode changes, also verify `opencode agent list` includes `ask (primary)`.

## Gotchas
- Do not edit generated or installed files under `~/.config/opencode`, `~/.claude`, `~/.codex`, or `~/.agents`; edit this repo and rerun `bash setup.sh`.
- Do not put secrets in `mcp/*.json` or `mcp/*.toml`; use `{env:...}` placeholders as the existing templates do.
- Preserve format differences: Claude agents use Markdown with YAML frontmatter, Codex has both Markdown docs and TOML config, OpenCode uses Markdown agent files in `agents/opencode/`.
