# Standalone opencode agents (plugin-free)

Replicates the agent **specifications** from the `oh-my-opencode-slim` plugin
using only official OpenCode agent definitions (`.md` files with frontmatter,
per https://opencode.ai). No plugin is installed — you get the same prompts,
roles, and permissions as `src/agents/*.ts`, adapted to the OpenCode V2 tool
surface.

## Agents

| File | Role | mode | Disabled by default |
|------|------|------|---------------------|
| `orchestrator.md` | workflow manager that delegates to specialists | primary | no |
| `explorer.md` | fast codebase recon + external docs/web research | subagent | no |
| `librarian.md` | legacy alias for explorer (external docs & library research) | subagent | no |
| `oracle.md` | architecture / review / debugging strategy | subagent | no |
| `designer.md` | UI/UX design & polish | subagent | no |
| `fixer.md` | bounded implementation execution | subagent | no |
| `observer.md` | visual/media analysis (needs vision model) | subagent | **yes** |
| `council.md` | multi-model consensus synthesis (no tools) | subagent | no |
| `councillor.md` | read-only council advisor (internal) | subagent + hidden | no |

Notes on fidelity vs the plugin (source synced 2026-11-16):
- Every agent omits `model`, matching the plugin's default (`model: undefined`
  → agents follow the global/session model).
- Permissions use the V2 `permissions` rule array: `question` is allowed only
  on the orchestrator (subagents deny it), `subagent` is unrestricted on the
  orchestrator, observer-only on explorer/oracle/designer, and denied on
  fixer/observer/council/councillor. V2 has no `cancel_task` or `wait_for_user`
  action, so the plugin's rules for those were dropped.
- The plugin merged `librarian` into `explorer`; this standalone keeps
  `librarian.md` as a legacy alias with the explorer prompt.
- Every subagent prompt carries the task-rejection suffix
  ("If a task is outside your role...").
- `observer.md` sets `disabled: true` to match `DEFAULT_DISABLED_AGENTS`;
  remove it to enable.
- The orchestrator prompt is a **static snapshot** of the latest
  `buildOrchestratorPrompt()` with all six routing lines (explorer, oracle,
  designer, fixer, council, observer). `observer` ships disabled; remove its
  `@observer` line from `orchestrator.md` if you keep it disabled.
- Agent-level `temperature` was removed: V2 preserves `agents.<name>.request`
  but does not send it with model requests. Set sampling on the provider, model,
  or variant instead.

## Setup

```bash
./setup.sh            # install to ~/.config/opencode/agents (global)
./setup.sh project    # install to ./.opencode/agents (this project)
```

The script copies the `.md` files to the target agent directory and sets
`"default_agent": "orchestrator"` in the corresponding `opencode.json`
(preserving existing keys). OpenCode reloads agent files on save; restart only
if a running session does not pick them up.

To enable explorer's `context7` / `gh_grep`, uncomment and fill the `mcp.servers`
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
  "orchestrator": { "model": "anthropic/claude-opus-5-5", "variant": "high" },
  "explorer":     { "model": "openai/gpt-6-luna", "variant": "medium" },
  "fixer":        { "model": "anthropic/claude-sonnet-5-5", "variant": "high" },
  "observer":     { "model": "openai/gpt-6.1-terra", "variant": "medium" }
}
```

Setup merges these into `opencode.json` under `agents.<name>.model` (joining
`model` and `variant` as `provider/model#variant`). Suggestions per role are
annotated in `models.json.example` (e.g. cheap/fast models for
`explorer`/`fixer`, vision model required for `observer`, strongest reasoning
for `oracle`). Override any subset — agents not listed keep following the global
model. You can also point setup at a different file with
`MODELS_FILE=/path/to/models.json`.

Per-agent models can instead be set directly in each `.md`'s frontmatter
(`model: provider/model-id`), or globally in `opencode.json` (`"model": ...`).

## Presets

Bundled model presets under `presets/`, mirrored from the plugin's
`src/cli/providers.ts` (`MODEL_MAPPINGS`), with local model refreshes for
`openai`, `hybrid`, `opencode-go`, `anthropic-openai`, and the two `openai-go`
presets. The `copilot`, `kimi`, and `zai-plan` files remain direct legacy
plugin mirrors. The refreshed presets were updated 2026-11-16 for the
October/November releases:

- `gpt-6.1-terra` (2026-10-26, $1/$5, 1.05M context, vision/PDF) is now the
  knowledge/design/bounded-implementation model. It beats Luna on capability,
  costs half of Sol, is much faster, and nearly matches Sol on vision; Sol stays
  on the hardest reasoning and coding lanes.
- `claude-fable-5-2` (2026-11-09, $8/$40, AA 65) takes the Anthropic oracle
  lane; `claude-sonnet-5-5` ($2/$10, 70.6% Terminal-Bench 4.0) takes bounded
  implementation; Opus 5.5 keeps orchestration and design.
- `kimi-k3.1-pro` (AA 55, same $15 Go quota as GLM-5.3) takes the Go oracle
  lane; `mimo-v2.6-pro` replaces the deprecated `mimo-v2.5` observer.

Each preset's `$comment` records the rationale and any legacy mapping.

| Preset | File | Agents |
|--------|------|--------|
| `openai` (default) | `presets/openai.json` | orchestrator, oracle, explorer, designer, fixer |
| `hybrid` | `presets/hybrid.json` | OpenAI + OpenCode Go mix — see below |
| `anthropic-openai` | `presets/anthropic-openai.json` | Anthropic + OpenAI mix — see below |
| `openai-go-performance` | `presets/openai-go-performance.json` | all 8 agents — OpenAI subscription + Go, task-first — see below |
| `openai-go-research` | `presets/openai-go-research.json` | all 8 agents — OpenAI subscription + Go, deeper research — see below |
| `opencode-go` | `presets/opencode-go.json` | + observer (vision model) |
| `kimi` | `presets/kimi.json` | the 5 core agents (legacy librarian mapping) |
| `copilot` | `presets/copilot.json` | the 5 core agents + legacy librarian mapping (github-copilot models) |
| `zai-plan` | `presets/zai-plan.json` | the 5 core agents + legacy librarian mapping |

### Balanced hybrid (`hybrid`)

For a machine with **both** OpenAI and OpenCode Go providers. The two bundled
presets are single-provider; this mixes to use the strongest model per agent:

| Agent | Model | Why |
|-------|-------|-----|
| orchestrator | `openai/gpt-6.1-sol` (`high`) | strongest reasoning tier; vision + tool-calling at $2/$10 |
| oracle | `openai/gpt-6.1-sol` (`xhigh`) | deepest reasoning for high-stakes review |
| designer | `openai/gpt-6.1-terra` (`medium`) | visual reasoning + writing at $1/$5; better fit than Luna |
| explorer | `opencode-go/deepseek-v4.1-flash` (`high`) | high-volume, cheap + fast |
| fixer | `opencode-go/deepseek-v4.1-flash` (`high`) | high-volume, cheap + fast |
| observer | `openai/gpt-6.1-terra` (`medium`) | image/PDF vision with a stronger model than Luna |

Rationale: OpenAI takes the reasoning and vision lanes (orchestrator, oracle,
designer, observer); OpenCode Go takes the two high-volume cost lanes (explorer,
fixer). GPT-6.1 Terra replaces Luna on design/vision because its Oct 2026
release puts it above Luna for visual reasoning and writing while staying at
$1/$5. DeepSeek V4.1-Flash keeps its $100 Go quota, 1M context, and native
image input for the high-volume lanes.

### Anthropic + OpenAI (`anthropic-openai`)

For a machine with **both** Anthropic and OpenAI providers. Fable 5.2 is now 20%
cheaper than Fable 5.1 and leads the Anthropic line, so the split is:

| Agent | Model | Why |
|-------|-------|-----|
| orchestrator | `anthropic/claude-opus-5-5` (`high`) | 1M ctx, image/PDF, $4/$20 for the always-on lane |
| oracle | `anthropic/claude-fable-5-2` (`high`) | newest frontier reasoning (AA 65) at $8/$40; low-volume lane |
| designer | `anthropic/claude-opus-5-5` (`medium`) | design taste on Opus; cheaper than Fable for a low-volume lane |
| explorer | `openai/gpt-6.1-terra` (`high`) | codebase recon + long-context docs research, image/PDF input, $1/$5 |
| fixer | `anthropic/claude-sonnet-5-5` (`high`) | 70.6% Terminal-Bench 4.0 at $2/$10; better coding value than Sol |
| observer | `openai/gpt-6.1-terra` (`medium`) | image/PDF vision; low-volume agent, so cost is moot |

Swap the orchestrator to `openai/gpt-6.1-sol` (`medium`) or
`openai/gpt-6-luna` (`max`, cheapest) if `opus-5-5` ($4/$20) is
too expensive or slow for the always-on lane.

### OpenAI subscription + OpenCode Go (`openai-go-performance`, `openai-go-research`)

Two task-first presets for a machine with **both** a ChatGPT/Codex
**subscription** and OpenCode Go. Both cover all eight standalone agents, so a
single preset fully defines the mapping. Within these presets model families are
restricted to GPT, DeepSeek, and GLM-5.3-Flash (GLM not required); GPT-6.1 Sol
runs only at `medium`/`high` and DeepSeek only at `high`/`max`. The research
preset shifts effort toward evidence work and bounded execution, and changes the
default council advisor:

| Agent | `openai-go-performance` | `openai-go-research` |
|-------|-------------------------|----------------------|
| orchestrator | `openai/gpt-6.1-sol` (`high`) | same |
| oracle | `openai/gpt-6.1-sol` (`high`) | same |
| explorer | `opencode-go/deepseek-v4.1-flash` (`high`) | `openai/gpt-6.1-sol` (`high`) |
| designer | `openai/gpt-6.1-terra` (`high`) | same |
| fixer | `openai/gpt-6.1-sol` (`high`) | `openai/gpt-6.1-sol` (`medium`) |
| observer | `openai/gpt-6.1-terra` (`medium`) | same |
| council | `openai/gpt-6.1-sol` (`high`) | same |
| councillor | `opencode-go/deepseek-v4.1-flash` (`high`) | `opencode-go/deepseek-v4.1-flash` (`max`) |

Rationale: `gpt-6.1-sol` stays on the hardest reasoning and coding lanes
(orchestrator, oracle, fixer, council). `gpt-6.1-terra` takes design and vision
because its launch positions it for visual reasoning, computer use, and writing
at half Sol's price; it scored 50.3% on Terminal-Bench 4.0 at max, so it is a
better fit for the design lane than Sol, not a claim that it is stronger. Go
`deepseek-v4.1-flash` handles efficient recon and docs research for the
performance preset (`explorer`), and provides the council's base
advisor: the `councillor` runs a DeepSeek model distinct from the OpenAI
synthesizer to give a default alternative perspective — that is not an automatic
multi-model council; real fanout still requires explicit per-seat model
overrides (see "What is NOT replicated").

`openai-go-research` differentiates by research fit rather than raw depth: the
explorer moves onto `gpt-6.1-sol` (`high`) for stronger evidence work, the
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
truth for IDs/variants — confirm `gpt-6.1-sol`, `gpt-6.1-terra`,
`gpt-6-luna`, `claude-fable-5-2`, and the Go model IDs exist for your account;
entitlement is checked separately from the recommendation. OpenCode Go is
quota-limited **per model** over rolling windows with **no automatic fallback** —
exhausting one model does not silently switch to another.

**Provider-use policy is not changed by these presets.** These templates only
write per-agent model mappings; they don't alter auth or the provider allow
policy. If your `opencode.json` already allows only OpenCode Go, add a minimal
`provider.use` rule for OpenAI **after** the deny-all and Go allow entries.
Given the existing shape in `config/opencode.json`:

```json
"policies": [
  { "action": "provider.use", "resource": "*", "effect": "deny" },
  { "action": "provider.use", "resource": "opencode-go", "effect": "allow" },
  { "action": "provider.use", "resource": "openai", "effect": "allow" }
]
```

`policies` is top-level in V2. `experimental.policies` still merges but is
deprecated; setup migrates it.

Notes: `observer` is mapped but ships **disabled** (remove `disabled: true`
from `agents/observer.md` to use it). A local `models.json` in this directory is
applied on top of the preset, so it overrides any agent (see "Models"). Switch
between the two with a different `--preset`; the presets are full eight-agent
mappings, so re-running setup leaves no stale variants behind. Command names
come from this `standalone-agents` directory, e.g.
`./setup.sh --preset openai-go-performance`.

Sources (researched 2026-11-16):
[Terra announcement](https://openai.com/index/introducing-gpt-6-1-terra) ·
[Sol announcement](https://openai.com/index/introducing-gpt-6-1-sol/) ·
[Sol model docs](https://developers.openai.com/api/docs/models/gpt-6.1-sol) ·
[Fable 5.2](https://www.anthropic.com/news/claude-fable-5-2) ·
[Haiku 5.5](https://platform.claude.com/docs/en/models/haiku-5-5/whats-new-haiku-5-5) ·
[Codex auth](https://developers.openai.com/codex/auth) ·
[OpenCode Go](https://opencode.ai/docs/console/go) ·
[models](https://opencode.ai/docs/models/) ·
[OpenCode changelog](https://opencode.ai/changelog).

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

- Background job board & session reconciliation — V2 subagents already run in
  the background and report when idle, but there is no plugin board: the
  orchestrator tracks each child's `sessionID` and continues it explicitly.
- Model fallback chains (`_modelArray`) & live failover on rate limits.
- Terminal multiplexer mirroring (tmux/Zellij/Herdr/cmux panes).
- Council **flatten mode** — per-model `councillor-<seat>` subagents are
  generated from a council preset; this standalone ships only the base
  `councillor`, so the orchestrator must fan out to councillors manually.
- Behavioral hooks (phase reminders, post-file nudges, task-retry, JSON error
  recovery, cache-safe injection, council-mode injection) and the plugin's runtime `/preset` switcher.
  (Bundled model presets are provided here, but they are static — applying one
  just writes per-agent models; there is no in-session preset switching.)
- No `cancel_task` or `wait_for_user` tool exists in V2. Stop a lane by not
  sending further follow-ups, and pause for the user by ending the turn.
