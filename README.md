# LLM Agents Config

Centralized configuration for AI coding agents — OpenCode, Claude Code, and Codex.

## Architecture

```
llm-agents-config/
├── context/
│   └── AGENTS.md              # Universal instructions (shared across all tools)
├── config/                    # Tool config templates (copied by setup.sh)
│   ├── opencode.json
│   ├── claude-settings.json
│   └── codex-config.toml
├── skills/                    # Single source of truth for ALL skills
│   ├── brainstorming/
│   ├── building-tasks/
│   ├── executing-plans/
│   ├── frontend-design/
│   ├── mermaid-diagram-specialist/
│   ├── opencode-config/
│   ├── reviewing-code/
│   ├── testing-code/
│   ├── writing-code/
│   └── writing-plans/
├── agents/                    # Per-tool agent definitions
│   ├── claude/                # Claude Code agents (ask, builder)
│   ├── codex/                 # Codex agents (ask, builder)
│   └── opencode/              # OpenCode agents (ask, builder, chat, explore)
├── commands/                  # OpenCode slash commands
│   └── clarify-plan.md
├── mcp/                       # MCP config reference templates
│   ├── opencode.json
│   ├── claude.json
│   └── codex.toml
├── agentic-sdlc/              # Claude plugin compatibility
│   ├── .claude-plugin/
│   │   └── plugin.json
│   ├── agents/ → ../agents/claude/
│   ├── commands/              # Claude slash commands
│   └── skills/ → ../skills/   # Symlink to central skills
└── setup.sh                   # One-time symlink script
```

## Setup

```bash
bash setup.sh
```

This creates symlinks from each tool's config directory to the central repo:

| Tool | Skill symlinks | Context | Config | Agents | Commands |
|---|---|---|---|---|---|
| OpenCode | `~/.config/opencode/skills/<name>` → `skills/<name>` | `~/.config/opencode/AGENTS.md` → `context/AGENTS.md` | `config/opencode.json` (copy) | `agents/opencode/*.md` → into `~/.config/opencode/agents/` | `commands/*.md` → into `~/.config/opencode/commands/` |
| Claude Code | `~/.claude/skills/<name>` → `skills/<name>` | `~/.claude/CLAUDE.md` with `@import` | `config/claude-settings.json` (copy) | `agents/claude/*.md` → `~/.claude/agents/` | — |
| Codex | `~/.agents/skills/<name>` → `skills/<name>` | `~/.codex/AGENTS.md` → `context/AGENTS.md` | `config/codex-config.toml` (copy + edit paths) | `agents/codex/*.{toml,md}` → `~/.codex/agents/` | — |

For OpenCode, `setup.sh` also verifies that `ask (primary)` and `chat (primary)` are discoverable when the `opencode` CLI is installed.

### Per-project setup

For each project, either:

1. **Symlink AGENTS.md**:
   ```bash
   ln -sf ~/Workspace/personal/llm-agents-config/context/AGENTS.md /path/to/project/AGENTS.md
   ```

2. **Or reference in `opencode.json`**:
   ```json
   { "instructions": ["~/Workspace/personal/llm-agents-config/context/AGENTS.md"] }
   ```

## How it works

### Skills

All three tools support the [Agent Skills standard](https://agentskills.io) (`SKILL.md` format). The central `skills/` directory is symlinked into each tool's skill discovery path:

- **OpenCode**: `~/.config/opencode/skills/`
- **Claude Code**: `~/.claude/skills/`
- **Codex**: `~/.agents/skills/`

Each tool discovers skills automatically from symlinks. Edit once in this repo, changes reflect everywhere.

### Context / Rules

The universal `context/AGENTS.md` contains coding standards shared across all tools:

- **OpenCode**: Reads `AGENTS.md` natively (project root or `~/.config/opencode/AGENTS.md`)
- **Claude Code**: `~/.claude/CLAUDE.md` uses `@import` to include the shared file, plus Claude-specific additions
- **Codex**: Reads `AGENTS.md` from project root (symlink or copy)

### MCP Config

MCP server configs are stored as reference templates in `mcp/`. Each tool uses a different format, so copy the relevant sections into the tool's actual config file:

| Tool | Config file | Template |
|---|---|---|
| OpenCode | `~/.config/opencode/opencode.json` → `mcp` section | `mcp/opencode.json` |
| Claude Code | `.mcp.json` or `~/.claude.json` | `mcp/claude.json` |
| Codex | `~/.codex/config.toml` → `[mcp]` sections | `mcp/codex.toml` |

### Agents

Agent definitions are per-tool since each has a different format:

| Tool | Directory | Format |
|---|---|---|
| Claude Code | `agents/claude/` | Markdown with YAML frontmatter |
| Codex | `agents/codex/` | TOML config |
| OpenCode | `agents/opencode/` | Markdown with YAML frontmatter |

OpenCode primary agents are selected with `Tab` or `opencode --agent <name>`. Only subagents are invoked with `@mentions`.

## Adding a new skill

1. Create a new directory under `skills/` with a `SKILL.md`:
   ```
   skills/my-new-skill/
   └── SKILL.md
   ```

2. Run `bash setup.sh` to create symlinks for all three tools.

3. The skill is automatically discovered by OpenCode, Claude Code, and Codex on their next session.

## Adding a skill only for one tool

Prefer adding skills to `skills/<name>/` in the repo so all tools can discover them.
If truly tool-only (e.g., uses tool-specific frontmatter), create directly:

- OpenCode only: `~/.config/opencode/skills/my-skill/SKILL.md`
- Claude Code only: `~/.claude/skills/my-skill/SKILL.md`
- Codex only: `~/.agents/skills/my-skill/SKILL.md`

## Files NOT symlinked (but templated)

These are copied (not symlinked) because tools may write to them, but templates live in `config/`:

- **Tool settings**: `config/opencode.json` → `~/.config/opencode/opencode.json`, `config/claude-settings.json` → `~/.claude/settings.json`, `config/codex-config.toml` → `~/.codex/config.toml` (requires path edits)
- **MCP configs**: Different JSON/TOML formats (templates provided in `mcp/`)
- **Codex config**: `config/codex-config.toml` → `~/.codex/config.toml` (requires path edits)

Truly machine-local (not centralized):

- **Auto-memory**: Per-project, per-tool (`~/.claude/projects/`)
- **Permissions/tool allowlists**: Tool-specific formats
