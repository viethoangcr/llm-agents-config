# LLM Agents Config

Centralized configuration for AI coding agents — OpenCode, Claude Code, and Codex.

## Architecture

```
llm-agents-config/
├── context/
│   └── AGENTS.md              # Universal instructions (shared across all tools)
├── skills/                    # Single source of truth for ALL skills
│   ├── brainstorming/
│   ├── building-tasks/
│   ├── executing-plans/
│   ├── mermaid-diagram-specialist/
│   ├── reviewing-code/
│   ├── testing-code/
│   ├── writing-code/
│   └── writing-plans/
├── agents/                    # Per-tool agent definitions
│   ├── claude/                # Claude Code agents
│   ├── codex/                 # Codex agents
│   └── opencode/              # OpenCode agents
├── rules/                     # Per-tool rules (placeholder)
│   ├── claude/
│   ├── opencode/
│   └── codex/
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

| Tool | Skill symlinks | Context |
|---|---|---|
| OpenCode | `~/.config/opencode/skills/<name>` → `skills/<name>` | `~/.config/opencode/AGENTS.md` → `context/AGENTS.md` |
| Claude Code | `~/.claude/skills/<name>` → `skills/<name>` | `~/.claude/CLAUDE.md` with `@import` |
| Codex | `~/.agents/skills/<name>` → `skills/<name>` | `~/.codex/AGENTS.md` → `context/AGENTS.md` |

For OpenCode, `setup.sh` also symlinks custom agents into `~/.config/opencode/agents/` and verifies that `ask (primary)` is discoverable when the `opencode` CLI is installed.

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
| OpenCode | `opencode.json` → `mcp` section | `mcp/opencode.json` |
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

Create it directly in the tool's skill directory (not symlinked):

- OpenCode only: `~/.config/opencode/skills/my-skill/SKILL.md`
- Claude Code only: `~/.claude/skills/my-skill/SKILL.md`
- Codex only: `~/.agents/skills/my-skill/SKILL.md`

## Files NOT centralized

These cannot be centralized because each tool uses a different format:

- **Tool settings**: `~/.config/opencode/opencode.json`, `~/.claude/settings.json`, `~/.codex/config.toml`
- **MCP configs**: Different JSON/TOML formats (templates provided in `mcp/`)
- **Auto-memory**: Per-project, per-tool (`~/.claude/projects/`)
- **Permissions/tool allowlists**: Tool-specific formats
