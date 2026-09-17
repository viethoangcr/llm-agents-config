# Standalone opencode agents (plugin-free)

Replicates the agent **specifications** from the `oh-my-opencode-slim` plugin
using only official OpenCode agent definitions (`.md` files with frontmatter,
per https://opencode.ai). No plugin is installed — you get the same prompts,
roles, temperatures, and permission objects as `src/agents/*.ts`.

## Agents

| File | Role | mode | temp | Disabled by default |
|------|------|------|------|---------------------|
| `orchestrator.md` | workflow manager that delegates to specialists | primary | 0.1 | no |
| `explorer.md` | fast codebase search / pattern matching | subagent | 0.1 | no |
| `librarian.md` | external docs & library research (context7, gh_grep) | subagent | 0.1 | no |
| `oracle.md` | architecture / review / debugging strategy | subagent | 0.1 | no |
| `designer.md` | UI/UX design & polish | subagent | 0.7 | no |
| `fixer.md` | bounded implementation execution | subagent | 0.2 | no |
| `observer.md` | visual/media analysis (needs vision model) | subagent | 0.1 | **yes** |
| `council.md` | multi-model consensus synthesis (no tools) | all | 0.1 | no |
| `councillor.md` | read-only council advisor (internal) | subagent + hidden | 0.2 | no |

Notes on fidelity vs the plugin:
- Every agent omits `model`, matching the plugin's default (`model: undefined`
  → agents follow the global/session model).
- Permissions replicate `applyDefaultPermissions()` (`question: allow` on all;
  `cancel_task`/`wait_for_user` only on the orchestrator) plus the strict
  read-only allowlist on `councillor` and the deny-all on `council`.
- Every subagent prompt carries the task-rejection suffix
  ("If a task is outside your role...").
- `observer.md` sets `disable: true` to match `DEFAULT_DISABLED_AGENTS`;
  remove it to enable.
- The orchestrator prompt is a **static snapshot** of `buildOrchestratorPrompt()`
  with all specialists enabled.

## Setup

```bash
./setup.sh            # install to ~/.config/opencode/agent (global)
./setup.sh project    # install to ./.opencode/agent (this project)
```

The script copies the `.md` files to the target agent directory and sets
`"default_agent": "orchestrator"` in the corresponding `opencode.json`
(preserving existing keys). Then **quit and restart opencode**.

To enable librarian's `context7` / `gh_grep`, uncomment and fill the `mcp`
block at the bottom of `setup.sh` (or add them to your own `opencode.json`).

## Models

By default every agent omits `model`, so all agents follow the global/session
model — this matches the plugin's default. To pin per-agent models, copy the
template and edit it, then re-run setup:

```bash
cp models.json.example models.json
# edit models.json -> set "provider/model-id" per agent
./setup.sh
```

`models.json` maps each agent to a model (and optional `variant`):

```json
{
  "orchestrator": { "model": "anthropic/claude-sonnet-4-6" },
  "explorer":     { "model": "openai/gpt-4o-mini" },
  "fixer":        { "model": "openai/gpt-4o" },
  "observer":     { "model": "anthropic/claude-sonnet-4-6" }
}
```

Setup merges these into `opencode.json` under `agent.<name>.model` (and
`.variant`). Suggestions per role are annotated in `models.json.example`
(e.g. cheap/fast models for `explorer`/`fixer`, vision model required for
`observer`, strongest reasoning for `oracle`). Override any subset — agents
not listed keep following the global model. You can also point setup at a
different file with `MODELS_FILE=/path/to/models.json`.

Per-agent models can instead be set directly in each `.md`'s frontmatter
(`model: provider/model-id`), or globally in `opencode.json` (`"model": ...`).

## Presets

Bundled model presets under `presets/`, mirrored from the plugin's
`src/cli/providers.ts` (`MODEL_MAPPINGS`) — except `opencode-go` and
`anthropic-openai`. `opencode-go` was updated 2026-09: DeepSeek V4.1-Flash on
the high-volume lanes, with GLM-5.3-Flash reserved for the frontend agent
(designer) only. `anthropic-openai` is a new dual-provider preset (see below).
Original plugin mappings are noted in each preset's `$comment`.

| Preset | File | Agents |
|--------|------|--------|
| `openai` (default) | `presets/openai.json` | orchestrator, oracle, librarian, explorer, designer, fixer |
| `hybrid` | `presets/hybrid.json` | OpenAI + OpenCode Go mix — see below |
| `anthropic-openai` | `presets/anthropic-openai.json` | Anthropic + OpenAI mix, fable/astra excluded — see below |
| `opencode-go` | `presets/opencode-go.json` | + observer (vision model) |
| `kimi` | `presets/kimi.json` | the 6 core agents |
| `copilot` | `presets/copilot.json` | the 6 core agents (github-copilot models) |
| `zai-plan` | `presets/zai-plan.json` | the 6 core agents |

### Balanced hybrid (`hybrid`)

For a machine with **both** OpenAI and OpenCode Go providers. The two bundled
presets are single-provider; this mixes to use the strongest model per agent:

| Agent | Model | Why |
|-------|-------|-----|
| orchestrator | `openai/gpt-5.6-terra` (`high`) | multimodal + strongest reasoning/tool-calling |
| oracle | `openai/gpt-5.6-sol` (`high`) | deepest reasoning for high-stakes review |
| designer | `openai/gpt-5.6-luna` (`medium`) | needs vision (screenshots/renders) + taste |
| librarian | `opencode-go/deepseek-v4.1-flash` (`high`) | long-context docs, cheap + fast |
| explorer | `opencode-go/deepseek-v4.1-flash` (`high`) | high-volume, cheap + fast |
| fixer | `opencode-go/deepseek-v4.1-flash` (`high`) | high-volume, cheap + fast |
| observer | `opencode-go/mimo-v2.5` | vision isolation |

Rationale: OpenAI takes the three reasoning/taste lanes (orchestrator,
oracle, designer); OpenCode Go takes the three high-volume cost lanes.
Note this is a quality preference, not a capability gap anymore: since
DeepSeek V4.1-Flash (native image input, Sept 2026) a pure `opencode-go`
setup handles multimodal work without OpenAI.

### Anthropic + OpenAI (`anthropic-openai`)

For a machine with **both** Anthropic and OpenAI providers. Uses each family's
flagships below the top tier — `claude-fable-5` and `gpt-6-astra` are excluded
(both $10/$50). Claude drives orchestration and design; OpenAI covers the
reasoning/implementation/vision/cost lanes:

| Agent | Model | Why |
|-------|-------|-----|
| orchestrator | `anthropic/claude-opus-5` (`high`) | strongest agentic/multimodal driver |
| oracle | `openai/gpt-5.6-sol` (`xhigh`) | deepest reasoning, independent family from the orchestrator |
| designer | `anthropic/claude-opus-5` (`medium`) | design taste: Vibe Code Bench 88.4%, 3:48/prompt; low-volume lane, so the premium is fine |
| explorer | `openai/gpt-5.6-luna` (`low`) | 1M ctx, cheapest lane |
| librarian | `openai/gpt-5.6-luna` (`high`) | long-context docs research, image/pdf input |
| fixer | `openai/gpt-5.6-terra` (`medium`) | near-flagship quality at the fastest per-prompt time (49.2 pts @ $0.20, 2:44 real-world) |
| observer | `openai/gpt-5.6-terra` (`medium`) | best vision of the three (MMMU-Pro 80.7%, gdp.pdf 24.7%); low-volume agent, so cost is moot |

Swap the orchestrator to `openai/gpt-5.6-terra` (`medium`, fastest) or
`openai/gpt-5.6-luna` (`max`, cheapest but slowest) if `opus-5` ($5/$25) is
too expensive or slow for the always-on lane.

Apply a preset when installing:

```bash
./setup.sh --preset openai        # global scope, OpenAI models
./setup.sh project --preset copilot
```

OpenCode has no native "preset" concept, so setup translates a preset into
`opencode.json` by setting `agent.<name>.model`/`.variant` for each listed
agent (agents not in the preset follow the global model). A `models.json`
in this directory is applied on top of the preset, so you can start from a
preset and tweak individual agents. Agents outside a preset are untouched;
to switch presets later, just re-run setup with a different `--preset`.

Note: in the plugin, the `opencode-go` preset also enables the observer
(`disabled_agents: []`), and the `opencode-go`/`anthropic-openai` presets map
it. This standalone ships `observer.md` with `disable: true`, so to use it,
remove that line from the file after setup.

## What is NOT replicated

Agent files cannot reproduce the plugin's **runtime machinery**:

- Background job board & session reconciliation — the plugin tracks `task`
  output, assigns aliases (`fix-1`), and injects an Active/Reusable board into
  the orchestrator prompt. Here the orchestrator must track `task_id`s itself.
- Model fallback chains (`_modelArray`) & live failover on rate limits.
- Terminal multiplexer mirroring (tmux/Zellij/Herdr/cmux panes).
- Council **flatten mode** — per-model `councillor-<seat>` subagents are
  generated from a council preset; this standalone ships only the base
  `councillor`, so the orchestrator must fan out to councillors manually.
- Behavioral hooks (phase reminders, post-file nudges, task-retry, JSON error
  recovery, cache-safe injection) and the plugin's runtime `/preset` switcher.
  (Bundled model presets are provided here, but they are static — applying one
  just writes per-agent models; there is no in-session preset switching.)
- `wait_for_user` in the orchestrator prompt is plugin-version-specific
  (OpenCode ≥ the version the plugin targets); on newer OpenCode remove that
  bullet if the tool does not exist.
