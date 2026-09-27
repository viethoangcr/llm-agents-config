---
name: opencode-config
description: >
  Guides modifications to OpenCode V2 agent configuration. Use this skill when:
  (1) editing opencode.json or cli.json settings,
  (2) creating or updating agent definitions (.md files in agents/opencode/),
  (3) creating or updating skills (skills/*/SKILL.md),
  (4) creating or updating custom commands (.opencode/commands/ or opencode.json commands entries),
  (5) adding or modifying MCP server configs,
  (6) creating or updating plugins (.opencode/plugins/),
  (7) updating AGENTS.md project rules.
  Each section includes a link to the official OpenCode V2 docs for the latest reference.
license: MIT
compatibility: opencode
metadata:
  version: "2.0.0"
---

# OpenCode Configuration (V2)

This skill helps you manage OpenCode V2 configuration — config files, agents, skills, commands, MCP servers, plugins, and project rules.

## Config (`opencode.json` / `cli.json`)

**Docs:** https://opencode.ai/v2/docs/config/

The main config file uses JSON or JSONC. Locations (later wins):

1. Global config (`~/.config/opencode/opencode.json(c)`) — user preferences
2. Project config (`<project>/opencode.json(c)`) — outermost to innermost
3. `.opencode/opencode.json(c)` — every discovered `.opencode` config overrides every direct config
4. `OPENCODE_CONFIG_CONTENT` env var

Include the schema for editor validation:

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "model": "anthropic/claude-sonnet-4-5",
}
```

Key top-level fields: `model`, `default_agent`, `permissions`, `agents`, `commands`, `providers`, `mcp`, `skills`, `plugins`, `references`, `formatter`, `lsp`, `compaction`, `watcher`, `share`, `update`, `snapshots`, `media`, `tool_output`, `experimental.policies`.

Use `{env:VARIABLE_NAME}` for env vars in config values.

Terminal/CLI preferences (theme, keybinds, diffs, session UI) live in the separate global `~/.config/opencode/cli.json`, not in `opencode.json`.

**CLI docs:** https://opencode.ai/v2/docs/cli/config/ | **Schema:** https://opencode.ai/v2/cli.json

## Agents

**Docs:** https://opencode.ai/v2/docs/agents/

Agents are specialized AI assistants with custom prompts, models, and permissions. Two types:

- **Primary agents** — main assistants cycled with Shift+Tab (e.g., Build, Plan)
- **Subagents** — invoked by primary agents or via @mention (e.g., General, Explore)

Define agents in `opencode.json` under the `agents` key, or as markdown files in:
- Global: `~/.config/opencode/agents/`
- Per-project: `.opencode/agents/`

Legacy `agent/`, `mode/`, and `modes/` directories are still discovered, but use `agents/` for new files.

**Markdown agent format (native V2):**
```yaml
---
description: What this agent does
mode: primary|subagent|all
model: provider/model-id#variant
hidden: false
disabled: false
steps: 10
color: "#ff6b6b"
request:
  body:
    temperature: 0.1
permissions:
  - action: edit
    resource: "*"
    effect: deny
  - action: shell
    resource: "*"
    effect: ask
---
System prompt content here...
```

The filename becomes the agent name (e.g., `review.md` creates `review`). The Markdown body is the agent's `system` prompt. Do not use legacy fields such as `temperature` (top level), `prompt`, `permission`, `tools`, `disable`, or `maxSteps`.

Note: V2 currently preserves `request.settings`, `request.headers`, and `request.body` but does not send them with model requests yet. Configure active request settings on the provider, model, or model variant instead.

Permission actions: `read`, `edit`, `glob`, `grep`, `shell`, `subagent`, `skill`, `question`, `webfetch`, `websearch`, `external_directory`, `<server>_<tool>` for MCP tools, and plugin-defined strings. Values: `allow`, `ask`, `deny`.

JSON configuration uses the same fields under `agents.<id>`, with `system` instead of the body.

### Agent File Locations in This Repo

Agent definitions live in `agents/opencode/` and are symlinked to `~/.config/opencode/agents/` by `setup.sh`.

## Skills

**Docs:** https://opencode.ai/v2/docs/skills/

Skills are reusable `SKILL.md` definitions loaded on-demand via the `skill` tool. Place them in:

- Project: `.opencode/skills/<name>/SKILL.md`
- Global: `~/.config/opencode/skills/<name>/SKILL.md`
- Also discovered from `.claude/skills/` and `.agents/skills/` for compatibility

**SKILL.md format:**
```yaml
---
name: Skill Display Name     # optional display label; the path-derived ID is the skill ID
description: >               # required for the model to discover the skill
  What this skill does and when to use it.
slash: true                  # optional; false hides it from interactive catalogs
metadata:
  opencode/autoinvoke: false # optional; false hides it from the model's available list
---
Markdown body with instructions...
```

Skill IDs are path-derived, exact, and case-sensitive: `skills/git-release/SKILL.md` has the ID `git-release`. Add extra sources with the `skills` array in config:

```jsonc
{ "skills": ["./team-skills", "https://example.com/opencode/skills/"] }
```

### Skill File Locations in This Repo

Skills live in `skills/<name>/SKILL.md` as the single source of truth. They are symlinked to all tool config dirs by `setup.sh`.

## Commands

**Docs:** https://opencode.ai/v2/docs/commands/

Custom slash commands for repetitive tasks. Define in `opencode.json` under the `commands` key, or as markdown files in:
- Global: `~/.config/opencode/commands/`
- Per-project: `.opencode/commands/`

The legacy `command/` directory is still discovered, but use `commands/` for new files.

**Markdown command format:**
```yaml
---
description: Run tests with coverage
agent: build
model: anthropic/claude-sonnet-4-5#high
subagent: true
---

Prompt template content here. Use $ARGUMENTS, $1, $2 etc. for args.
Use !`command` to inject shell output.
```

The Markdown body is the template; do not put `template` in frontmatter. `subtask` remains a deprecated alias for `subagent`. Commands override built-ins with the same name.

## MCP Servers

**Docs:** https://opencode.ai/v2/docs/mcp-servers/

MCP servers live under `mcp.servers` (not directly under `mcp`), and use `disabled` instead of `enabled`:

**Local** (runs as a process):
```json
{
  "mcp": {
    "servers": {
      "my-server": {
        "type": "local",
        "command": ["npx", "-y", "my-mcp-command"],
        "environment": { "MY_ENV": "value" }
      }
    }
  }
}
```

**Remote** (HTTP endpoint):
```json
{
  "mcp": {
    "servers": {
      "my-server": {
        "type": "remote",
        "url": "https://mcp.example.com/mcp",
        "headers": { "Authorization": "Bearer {env:MY_KEY}" }
      }
    }
  }
}
```

OAuth is automatic for remote servers; OAuth client fields use snake case (`client_id`, `client_secret`, `callback_port`, `redirect_uri`). Global timeouts live under `mcp.timeout` (`startup`, `catalog`, `execution`). Manage servers with `opencode mcp add/list/auth/logout` or `/mcps`.

MCP tools can be controlled per-agent via `permissions` with `<server>_<tool>` action patterns.

### MCP File Locations in This Repo

MCP templates are in `mcp/opencode.json`. Users copy relevant sections into their real config. Do not put secrets in templates; use `{env:...}` placeholders.

## Plugins

**Docs:** https://opencode.ai/v2/docs/plugins/ and https://opencode.ai/v2/docs/build/plugins/

Plugins extend OpenCode with tools, hooks, and integrations. Configure them in `opencode.json` under `plugins`:

```jsonc
{
  "plugins": ["opencode-example-plugin", { "package": "./plugins/local", "options": { "enabled": true } }]
}
```

OpenCode also auto-discovers direct `.ts`/`.js` files and plugin package directories from `.opencode/plugins/` and the global `~/.config/opencode/plugins/`. Manage them with `opencode plugin add/list/update/remove`.

V1 plugin implementations do not run in V2; port them with the plugin migration guide.

## Rules / AGENTS.md

**Docs:** https://opencode.ai/v2/docs/instructions/

Project instructions go in `AGENTS.md`. OpenCode loads the global `~/.config/opencode/AGENTS.md` first, then every `AGENTS.md` from the workspace up toward the home directory. V2 recognizes `AGENTS.md` only (no `CLAUDE.md` fallback).

The `instructions` config field is accepted but not resolved in V2; use `AGENTS.md` for active instructions.

### Rule File Locations in This Repo

- `context/AGENTS.md` — shared global instructions (tool-agnostic)
- `AGENTS.md` — repo-specific instructions (setup, gotchas, key files)

## Permissions

**Docs:** https://opencode.ai/v2/docs/permissions/ and https://opencode.ai/v2/docs/tools/ and https://opencode.ai/v2/docs/policies/

Control tool access with ordered rules; the last matching rule wins:

```json
{
  "permissions": [
    { "action": "shell", "resource": "*", "effect": "ask" },
    { "action": "shell", "resource": "git status *", "effect": "allow" },
    { "action": "edit", "resource": "*", "effect": "deny" },
    { "action": "skill", "resource": "internal-*", "effect": "deny" }
  ]
}
```

Permission values: `allow` (no prompt), `ask` (prompt for approval), `deny` (blocked). Glob patterns use `*` and `?`; a shell pattern ending in ` *` also matches the command without arguments.

Provider allow/deny lists moved to policies under `experimental.policies` (`provider.use` statements), which use the same ordered last-match-wins format.

## Key Rules for This Repo

Skills are the single source of truth in `skills/<name>/SKILL.md` and are symlinked to all tool config dirs.

Agent definitions in `agents/opencode/` follow the OpenCode V2 markdown agent format.

Do not edit files under `~/.config/opencode/`, `~/.claude/`, `~/.codex/`, or `~/.agents/` — edit this repo and re-run `bash setup.sh`.

After adding a new skill to `skills/<name>/`, update `setup.sh` if needed and run it to create symlinks.

After changing agent definitions or setup.sh symlink behavior, verify with `opencode debug agents`.
