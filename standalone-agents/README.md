# Standalone opencode agents (plugin-free)

Replicates the agent **specifications** from the `oh-my-opencode-slim` plugin
using only official OpenCode agent definitions (`.md` files with frontmatter,
per https://opencode.ai). No plugin is installed — you get the same prompts,
roles, temperatures, and permissions as `src/agents/*.ts`.

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
- Permissions use the V2 `permissions` rule array (`question: allow` on all;
  `cancel_task`/`wait_for_user` only on the orchestrator) plus the strict
  read-only allowlist on `councillor` and the deny-all on `council`.
- Every subagent prompt carries the task-rejection suffix
  ("If a task is outside your role...").
- `observer.md` sets `disabled: true` to match `DEFAULT_DISABLED_AGENTS`;
  remove it to enable.
- The orchestrator prompt is a **static snapshot** of `buildOrchestratorPrompt()`
  with all specialists enabled.

## Setup

```bash
./setup.sh            # install to ~/.config/opencode/agents (global)
./setup.sh project    # install to ./.opencode/agents (this project)
```

The script copies the `.md` files to the target agent directory and sets
`"default_agent": "orchestrator"` in the corresponding `opencode.json`
(preserving existing keys). Then **quit and restart opencode**.

To enable librarian's `context7` / `gh_grep`, uncomment and fill the `mcp.servers`
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

Setup merges these into `opencode.json` under `agents.<name>.model` (joining
`model` and `variant` as `provider/model#variant`, and writing `temperature` to
`agents.<name>.request.body.temperature`). Suggestions per role are annotated in
`models.json.example` (e.g. cheap/fast models for `explorer`/`fixer`, vision
model required for `observer`, strongest reasoning for `oracle`). Override any
subset — agents not listed keep following the global model. You can also point
setup at a different file with `MODELS_FILE=/path/to/models.json`.

Per-agent models can instead be set directly in each `.md`'s frontmatter
(`model: provider/model-id`), or globally in `opencode.json` (`"model": ...`).

## Presets

Bundled model presets under `presets/`, mirrored from the plugin's
`src/cli/providers.ts` (`MODEL_MAPPINGS`) — except `opencode-go`,
`anthropic-openai`, `openai-go-performance`, and `openai-go-research`.
`opencode-go` was updated 2026-09: DeepSeek V4.1-Flash on
the high-volume lanes, with GLM-5.3-Flash reserved for the frontend agent
(designer) only. `anthropic-openai` is a new dual-provider preset (see below).
The `openai`, `hybrid`, and `anthropic-openai` presets were refreshed
2026-09-30, upgrading the reasoning lanes to the newer `gpt-6.1-sol`
(Claude Opus 5.5 unchanged); the GPT-6 family keeps `luna` for cost/vision.
`gpt-6-luna` is never used below `medium`: `medium` for
simple read/summarize lanes, `high`/`xhigh` for more complex ones. Original
plugin mappings are noted in each preset's `$comment`.

| Preset | File | Agents |
|--------|------|--------|
| `openai` (default) | `presets/openai.json` | orchestrator, oracle, librarian, explorer, designer, fixer |
| `hybrid` | `presets/hybrid.json` | OpenAI + OpenCode Go mix — see below |
| `anthropic-openai` | `presets/anthropic-openai.json` | Anthropic + OpenAI mix, fable/astra excluded — see below |
| `openai-go-performance` | `presets/openai-go-performance.json` | all 9 agents — OpenAI subscription + Go, task-first — see below |
| `openai-go-research` | `presets/openai-go-research.json` | all 9 agents — OpenAI subscription + Go, deeper research — see below |
| `opencode-go` | `presets/opencode-go.json` | + observer (vision model) |
| `kimi` | `presets/kimi.json` | the 6 core agents |
| `copilot` | `presets/copilot.json` | the 6 core agents (github-copilot models) |
| `zai-plan` | `presets/zai-plan.json` | the 6 core agents |

### Balanced hybrid (`hybrid`)

For a machine with **both** OpenAI and OpenCode Go providers. The two bundled
presets are single-provider; this mixes to use the strongest model per agent:

| Agent | Model | Why |
|-------|-------|-----|
| orchestrator | `openai/gpt-6.1-sol` (`high`) | newest reasoning tier; vision + tool-calling at $2/$10 |
| oracle | `openai/gpt-6.1-sol` (`xhigh`) | deepest reasoning for high-stakes review |
| designer | `openai/gpt-6-luna` (`medium`) | needs vision (screenshots/renders) + taste |
| librarian | `opencode-go/deepseek-v4.1-flash` (`high`) | long-context docs, cheap + fast |
| explorer | `opencode-go/deepseek-v4.1-flash` (`high`) | high-volume, cheap + fast |
| fixer | `opencode-go/deepseek-v4.1-flash` (`high`) | high-volume, cheap + fast |
| observer | `opencode-go/mimo-v2.5` | vision isolation |

Rationale: OpenAI takes the three reasoning/taste lanes (orchestrator,
oracle, designer); OpenCode Go takes the three high-volume cost lanes.
GPT-6 `sol`/`luna` replace the GPT-5.6 generations at the same or lower
price (sol $2/$10, luna $0.10/$0.50) with 1.05M context and image/PDF input.
Note this is a quality preference, not a capability gap anymore: since
DeepSeek V4.1-Flash (native image input, Sept 2026) a pure `opencode-go`
setup handles multimodal work without OpenAI.

### Anthropic + OpenAI (`anthropic-openai`)

For a machine with **both** Anthropic and OpenAI providers. Uses each family's
flagships below the top tier — `claude-fable-5-1` and `gpt-6-astra` are excluded
(both $10/$50). Claude drives orchestration and design; OpenAI covers the
reasoning/implementation/vision/cost lanes:

| Agent | Model | Why |
|-------|-------|-----|
| orchestrator | `anthropic/claude-opus-5-5` (`high`) | newest Opus: 1M ctx, image/PDF, cheaper than Opus 5 ($4/$20 vs $5/$25) |
| oracle | `openai/gpt-6.1-sol` (`xhigh`) | deepest reasoning, independent family from the orchestrator |
| designer | `anthropic/claude-opus-5-5` (`medium`) | design taste on the newest Opus; low-volume lane |
| explorer | `openai/gpt-6-luna` (`medium`) | 1.05M ctx, cheapest lane ($0.10/$0.50) |
| librarian | `openai/gpt-6-luna` (`high`) | long-context docs research, image/PDF input |
| fixer | `openai/gpt-6.1-sol` (`medium`) | latest-generation mid-tier; lower effort than the oracle for the implementation lane |
| observer | `openai/gpt-6.1-sol` (`medium`) | image/PDF vision; low-volume agent, so cost is moot |

Swap the orchestrator to `openai/gpt-6.1-sol` (`medium`) or
`openai/gpt-6-luna` (`max`, cheapest) if `opus-5-5` ($4/$20) is
too expensive or slow for the always-on lane.

### OpenAI subscription + OpenCode Go (`openai-go-performance`, `openai-go-research`)

Two task-first presets for a machine with **both** a ChatGPT/Codex
**subscription** and OpenCode Go. Both cover all nine standalone agents, so a
single preset fully defines the mapping. Within these presets model families are
restricted to GPT, DeepSeek, and GLM-5.3-Flash (GLM not required); GPT-6.1 Sol
runs only at `medium`/`high` and DeepSeek only at `high`/`max`. The research
preset shifts effort toward evidence work and bounded execution, and changes the
default council advisor:

| Agent | `openai-go-performance` | `openai-go-research` |
|-------|-------------------------|----------------------|
| orchestrator | `openai/gpt-6.1-sol` (`high`) | same |
| oracle | `openai/gpt-6.1-sol` (`high`) | same |
| librarian | `opencode-go/deepseek-v4.1-flash` (`high`) | `openai/gpt-6.1-sol` (`high`) |
| explorer | `opencode-go/deepseek-v4.1-flash` (`high`) | same |
| designer | `openai/gpt-6.1-sol` (`high`) | same |
| fixer | `openai/gpt-6.1-sol` (`high`) | `openai/gpt-6.1-sol` (`medium`) |
| observer | `openai/gpt-6-luna` (`medium`) | same |
| council | `openai/gpt-6.1-sol` (`high`) | same |
| councillor | `opencode-go/deepseek-v4.1-flash` (`high`) | `opencode-go/deepseek-v4.1-flash` (`max`) |

Rationale: `gpt-6.1-sol` is OpenAI's flagship reasoning/coding model with
multimodal input, so it takes the synthesis, decision, implementation, and
design lanes (orchestrator, oracle, designer, fixer, council); `gpt-6-luna`
covers vision (`observer`). This is a role-based preference from documented
capabilities — **not** a measured claim that Sol is superior at design or task
execution. Go `deepseek-v4.1-flash` handles efficient recon (`explorer`) and
docs/performance research (`librarian`, performance preset), and provides the
council's base advisor: the `councillor` runs a DeepSeek model distinct from the
OpenAI synthesizer to give a default alternative perspective — that is not an
automatic multi-model council; real fanout still requires explicit per-seat
model overrides (see "What is NOT replicated").

`openai-go-research` differentiates by research fit rather than raw depth: the
librarian moves onto `gpt-6.1-sol` (`high`) for stronger evidence work, the
councillor runs DeepSeek at `max`, and the fixer drops to `medium` for bounded
execution. Both presets keep the oracle at Sol `high` — research does **not**
assert a deeper oracle. Variant depth is a tradeoff, not a guaranteed quality
win; higher variants run slower and consume more quota.

The family and variant constraints apply to these two presets only — the other
bundled presets are unchanged. GLM-5.3-Flash is permitted but not required;
neither preset currently uses it.

**Entitlement and auth (separate from this repo's templates).** The `openai`
provider must use your ChatGPT/Codex **OAuth** login, not an API key, for
subscription-covered access.
OpenAI Business/Enterprise accounts are supported when the workplace grants the
Codex entitlement and the admin permits OAuth; an API-key billing setup does
**not** grant subscription access. Verify your account's available models via
`/models` before applying a preset. The live model catalog is the source of
truth for IDs/variants — confirm `gpt-6.1-sol`, `gpt-6-luna`, and the Go model
IDs exist for your account; entitlement is checked separately from the
recommendation. OpenCode Go is quota-limited **per model** over rolling windows
with **no automatic fallback** — exhausting one model does not silently switch
to another.

**Provider-use policy is not changed by these presets.** These templates only
write per-agent model mappings; they don't alter auth or the provider allow
policy. If your `opencode.json` already allows only OpenCode Go, add a minimal
`provider.use` rule for OpenAI **after** the deny-all and Go allow entries.
Given the existing shape in `config/opencode.json`:

```json
"experimental": {
  "policies": [
    { "action": "provider.use", "resource": "*", "effect": "deny" },
    { "action": "provider.use", "resource": "opencode-go", "effect": "allow" },
    { "action": "provider.use", "resource": "openai", "effect": "allow" }
  ]
}
```

Notes: `observer` is mapped but ships **disabled** (remove `disabled: true`
from `agents/observer.md` to use it). A local `models.json` in this directory is
applied on top of the preset, so it overrides any agent (see "Models"). Switch
between the two with a different `--preset`; the presets are full nine-agent
mappings, so re-running setup leaves no stale variants behind. Command names
come from this `standalone-agents` directory, e.g.
`./setup.sh --preset openai-go-performance`.

Sources (researched 2026-09-30):
[Sol announcement](https://openai.com/index/introducing-gpt-6-1-sol/) ·
[Sol model docs](https://developers.openai.com/api/docs/models/gpt-6.1-sol) ·
[Codex auth](https://developers.openai.com/codex/auth) ·
[OpenCode Go console](https://opencode.ai/v2/docs/console/go/) ·
[providers](https://opencode.ai/v2/docs/cli/providers/) ·
[models](https://opencode.ai/v2/docs/models/).

Apply a preset when installing:

```bash
./setup.sh --preset openai        # global scope, OpenAI models
./setup.sh project --preset copilot
```

OpenCode has no native "preset" concept, so setup translates a preset into
`opencode.json` by setting `agents.<name>.model` to `provider/model#variant`
for each listed agent (agents not in the preset follow the global model). A
`models.json` in this directory is applied on top of the preset, so you can
start from a preset and tweak individual agents. Agents outside a preset are
untouched; to switch presets later, just re-run setup with a different
`--preset`.

Note: in the plugin, the `opencode-go` preset also enables the observer
(`disabled_agents: []`), and the `opencode-go`/`anthropic-openai` presets map
it. This standalone ships `observer.md` with `disabled: true`, so to use it,
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
