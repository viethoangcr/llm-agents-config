---
name: opencode-config
description: >
  Guides modifications to OpenCode agent configuration. Use this skill when:
  (1) editing opencode.json or tui.json settings,
  (2) creating or updating agent definitions (.md files in agents/opencode/),
  (3) creating or updating skills (skills/*/SKILL.md),
  (4) creating or updating custom commands (.opencode/commands/ or opencode.json command entries),
  (5) adding or modifying MCP server configs,
  (6) creating or updating custom tools (.opencode/tools/),
  (7) updating AGENTS.md project rules.
  Each section includes a link to the official OpenCode docs for the latest reference.
license: MIT
compatibility: opencode
metadata:
  version: "1.0.0"
---

# OpenCode Configuration

This skill helps you manage OpenCode configuration — config files, agents, skills, commands, MCP servers, custom tools, and project rules.

## Config (`opencode.json` / `tui.json`)

**Docs:** https://opencode.ai/docs/config/

The main config file uses JSON or JSONC format. Multiple config files are merged (not replaced) in this precedence order (later wins):

1. Remote config (`.well-known/opencode`) — organizational defaults
2. Global config (`~/.config/opencode/opencode.json`) — user preferences
3. Custom config (`OPENCODE_CONFIG` env var)
4. Project config (`opencode.json` in project root)
5. `.opencode` directories — agents, commands, plugins
6. Inline config (`OPENCODE_CONFIG_CONTENT` env var)
7. Managed config files (admin-enforced, highest priority)

Key schema sections: `provider`, `model`, `small_model`, `server`, `shell`, `tools`, `permission`, `agent`, `command`, `mcp`, `plugin`, `formatter`, `lsp`, `instructions`, `disabled_providers`, `enabled_providers`, `compaction`, `watcher`, `share`, `autoupdate`, `snapshot`.

TUI settings (theme, keymap, scroll_speed, mouse, diff_style) go in a separate `tui.json` or `tui.jsonc`.

Use `{env:VARIABLE_NAME}` for env vars and `{file:path/to/file}` for file contents in config values.

**Schema URLs:** https://opencode.ai/config.json and https://opencode.ai/tui.json

## Agents

**Docs:** https://opencode.ai/docs/agents/

Agents are specialized AI assistants with custom prompts, models, and tool access. Two types:

- **Primary agents** — main assistants cycled via Tab key (e.g., Build, Plan)
- **Subagents** — invoked by primary agents or via @mention (e.g., General, Explore)

Define agents in `opencode.json` under `agent` key, or as markdown files in:
- Global: `~/.config/opencode/agents/`
- Per-project: `.opencode/agents/`

**Markdown agent format:**
```yaml
---
description: What this agent does
mode: primary|subagent|all
model: provider/model-id
temperature: 0.1
permission:
  edit: deny
  bash:
    "*": ask
    "git diff": allow
  skill:
    "my-skill": allow
color: "#ff6b6b"
steps: 10
---
System prompt content here...
```

The filename becomes the agent name (e.g., `review.md` creates `review`).

Permissions keys: `read`, `edit` (covers write/edit/apply_patch), `glob`, `grep`, `list`, `bash`, `task`, `todowrite`, `webfetch`, `websearch`, `lsp`, `skill`, `question`, `doom_loop`, `external_directory`. Values: `"allow"`, `"ask"`, `"deny"`.

Use `opencode agent create` for interactive agent creation.

### Agent File Locations in This Repo

Agent definitions live in `agents/opencode/` and are symlinked to `~/.config/opencode/agents/` by `setup.sh`.

## Skills

**Docs:** https://opencode.ai/docs/skills/

Skills are reusable SKILL.md definitions loaded on-demand via the `skill` tool. Place them in:

- Project: `.opencode/skills/<name>/SKILL.md`
- Global: `~/.config/opencode/skills/<name>/SKILL.md`
- Also discovered from `.claude/skills/` and `.agents/skills/` for compatibility

**SKILL.md format:**
```yaml
---
name: skill-name           # lowercase, hyphens only, 1-64 chars, must match dir name
description: >             # 1-1024 chars, include trigger conditions
  What this skill does and when to use it.
license: MIT               # optional
compatibility: opencode    # optional
metadata:                  # optional, string-to-string map
  version: "1.0.0"
---
Markdown body with instructions...
```

Name regex: `^[a-z0-9]+(-[a-z0-9]+)*$`

Control skill access via permissions: `"permission": { "skill": { "*": "allow", "internal-*": "deny" } }`

### Skill File Locations in This Repo

Skills live in `skills/<name>/SKILL.md` as the single source of truth. They are symlinked to all tool config dirs by `setup.sh`.

## Commands

**Docs:** https://opencode.ai/docs/commands/

Custom slash commands for repetitive tasks. Define in `opencode.json` under `command` key, or as markdown files in:
- Global: `~/.config/opencode/commands/`
- Per-project: `.opencode/commands/`

**Markdown command format:**
```yaml
---
description: Run tests with coverage
agent: build
model: anthropic/claude-sonnet-4-5
subtask: true
---
Prompt template content here. Use $ARGUMENTS, $1, $2 etc. for args.
Use !`command` to inject shell output.
Use @filename to include file contents.
```

Commands override built-ins with the same name.

## MCP Servers

**Docs:** https://opencode.ai/docs/mcp-servers/

MCP servers add external tools via the Model Context Protocol. Two types:

**Local** (runs as a process):
```json
{
  "mcp": {
    "my-server": {
      "type": "local",
      "command": ["npx", "-y", "my-mcp-command"],
      "enabled": true,
      "environment": { "MY_ENV": "value" },
      "timeout": 5000
    }
  }
}
```

**Remote** (HTTP endpoint):
```json
{
  "mcp": {
    "my-server": {
      "type": "remote",
      "url": "https://mcp.example.com/mcp",
      "enabled": true,
      "headers": { "Authorization": "Bearer {env:MY_KEY}" },
      "oauth": {}
    }
  }
}
```

OpenCode handles OAuth automatically for remote servers. Use `opencode mcp auth <name>` to authenticate.

MCP tools can be controlled per-agent via `permission` with glob patterns (e.g., `"my-server_*": "deny"`).

### MCP File Locations in This Repo

MCP templates are in `mcp/opencode.json`. Users copy relevant sections into their real config. Do not put secrets in templates; use `{env:...}` placeholders.

## Custom Tools

**Docs:** https://opencode.ai/docs/custom-tools/

Custom tools are TypeScript/JavaScript files the LLM can call. Place in:
- Global: `~/.config/opencode/tools/`
- Per-project: `.opencode/tools/`

**Tool definition (`.opencode/tools/my-tool.ts`):**
```typescript
import { tool } from "@opencode-ai/plugin"

export default tool({
  description: "Tool description",
  args: {
    param: tool.schema.string().describe("Parameter description"),
  },
  async execute(args, context) {
    // context: { agent, sessionID, messageID, directory, worktree }
    return "result"
  },
})
```

The filename becomes the tool name. Multiple exports per file create `<file>_<export>` tools. Custom tools can override built-in tools with the same name.

## Rules / AGENTS.md

**Docs:** https://opencode.ai/docs/rules/

Project instructions go in `AGENTS.md` in the project root. Created via `/init` command or manually.

**Precedence order:**
1. Project `AGENTS.md` (or `CLAUDE.md` as fallback)
2. Global `~/.config/opencode/AGENTS.md` (or `~/.claude/CLAUDE.md` as fallback)

Use `opencode.json` `"instructions"` field to include additional files:
```json
{
  "instructions": ["CONTRIBUTING.md", "docs/guidelines.md", ".cursor/rules/*.md"]
}
```

Remote URLs are also supported in `instructions`.

### Rule File Locations in This Repo

- `context/AGENTS.md` — shared global instructions (tool-agnostic)
- `AGENTS.md` — repo-specific instructions (setup, gotchas, key files)

## Permissions

**Docs:** https://opencode.ai/docs/permissions/ and https://opencode.ai/docs/tools/

Control tool access with `permission` in `opencode.json` or per-agent:

```json
{
  "permission": {
    "edit": "deny",
    "bash": {
      "*": "ask",
      "git status": "allow",
      "npm test": "allow"
    },
    "skill": {
      "internal-*": "deny",
      "my-skill": "allow"
    }
  }
}
```

Permission values: `"allow"` (no prompt), `"ask"` (prompt for approval), `"deny"` (disabled).

Glob patterns supported for wildcard matching. Last matching rule wins.

## Key Rules for This Repo

Skills are the single source of truth in `skills/<name>/SKILL.md` and are symlinked to all tool config dirs.

Agent definitions in `agents/opencode/` follow the OpenCode markdown agent format.

Do not edit files under `~/.config/opencode/`, `~/.claude/`, `~/.codex/`, or `~/.agents/` — edit this repo and re-run `bash setup.sh`.

After adding a new skill to `skills/<name>/`, update `setup.sh` if needed and run it to create symlinks.

After changing agent definitions or setup.sh symlink behavior, verify with `opencode agent list`.
