#!/usr/bin/env bash
#
# Install the standalone opencode agents WITHOUT the oh-my-opencode-slim plugin.
#
# Usage:
#   ./setup.sh                          # install to global scope (~/.config/opencode/agent)
#   ./setup.sh project                  # install to project scope (.opencode/agent in cwd)
#   ./setup.sh --preset openai          # global scope + apply the openai model preset
#   ./setup.sh project --preset openai  # project scope + openai preset
#
# Available presets (mirrored from the plugin's src/cli/providers.ts):
#   openai, opencode-go, kimi, copilot, zai-plan  (plugin mappings)
#   hybrid                                        (Balanced hybrid — see README)
#
# Environment:
#   OPENCODE_CONFIG  path to the opencode.json to merge default_agent into.
#                    Defaults to the scope's config file.
#   MODELS_FILE      optional JSON mapping per-agent models, e.g.
#                    {"orchestrator":"anthropic/claude-sonnet-4-6",
#                     "fixer":"openai/gpt-4o"}. Defaults to ./models.json in
#                    this directory if present. Applied on top of any preset.
#                    See README.md "Models".
#
# This only installs the agent definitions. It does NOT reproduce plugin
# runtime behavior (background job board, model fallback chains, tmux
# mirroring, hooks, council flatten mode). See README.md.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_SRC="$SCRIPT_DIR/agents"
PRESETS_SRC="$SCRIPT_DIR/presets"
MODELS_FILE="${MODELS_FILE:-$SCRIPT_DIR/models.json}"

SCOPE="global"
PRESET=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    global|project) SCOPE="$1"; shift ;;
    --preset) PRESET="${2:-}"; shift 2 ;;
    --preset=*) PRESET="${1#*=}"; shift ;;
    *)
      echo "usage: $0 [global|project] [--preset <name>]" >&2
      exit 2
      ;;
  esac
done

if [[ ! -d "$AGENTS_SRC" ]]; then
  echo "error: agents source dir not found: $AGENTS_SRC" >&2
  exit 1
fi

case "$SCOPE" in
  global)
    DEST="${OPENCODE_AGENT_DIR:-$HOME/.config/opencode/agent}"
    CONFIG="${OPENCODE_CONFIG:-$HOME/.config/opencode/opencode.json}"
    ;;
  project)
    DEST=".opencode/agent"
    CONFIG="${OPENCODE_CONFIG:-opencode.json}"
    ;;
esac

mkdir -p "$DEST"
cp "$AGENTS_SRC"/*.md "$DEST"/
echo "Installed agents -> $DEST"
ls -1 "$DEST"/*.md

# Merge default_agent = orchestrator into the config (preserving existing keys).
if ! command -v python3 >/dev/null 2>&1; then
  echo "warning: python3 not found; skipping default_agent config merge." >&2
  echo "Manually set \"default_agent\": \"orchestrator\" in $CONFIG" >&2
  exit 0
fi

mkdir -p "$(dirname "$CONFIG")"
python3 - "$CONFIG" "$MODELS_FILE" "$PRESETS_SRC" "$PRESET" <<'PY'
import json, os, sys

path, models_path, presets_src, preset = sys.argv[1:5]
data = {}
if os.path.exists(path):
    with open(path, encoding="utf-8") as f:
        try:
            data = json.load(f)
        except json.JSONDecodeError as e:
            print(f"warning: {path} is not valid JSON; backing it up and rewriting.", file=sys.stderr)
            os.rename(path, path + ".bak")
            data = {}

data.setdefault("$schema", "https://opencode.ai/config.json")
data["default_agent"] = "orchestrator"
agents = data.setdefault("agent", {})

def merge_models(models, source):
    applied = 0
    for name, cfg in models.items():
        if not isinstance(cfg, dict):
            continue  # ignore non-agent keys like "$comment"
        merged = {k: v for k, v in cfg.items() if k in ("model", "variant", "temperature")}
        if merged:
            agents.setdefault(name, {}).update(merged)
            applied += 1
    if applied:
        print(f"merged per-agent models from {source}")

# 1. Bundled preset (--preset openai etc.) as the base model mapping.
if preset:
    preset_path = os.path.join(presets_src, f"{preset}.json")
    if not os.path.exists(preset_path):
        available = sorted(
            f[:-5] for f in os.listdir(presets_src) if f.endswith(".json")
        )
        print(f"error: unknown preset '{preset}'. Available: {', '.join(available)}", file=sys.stderr)
        sys.exit(2)
    with open(preset_path, encoding="utf-8") as f:
        merge_models(json.load(f), preset_path)

# 2. Optional user models.json overrides on top of the preset.
if os.path.exists(models_path):
    with open(models_path, encoding="utf-8") as f:
        merge_models(json.load(f), models_path)

# Optional: librarian expects context7 + gh_grep MCP servers. Uncomment and
# fill in real server config to enable them; otherwise all agents share
# whatever MCP servers opencode has configured globally.
# data.setdefault("mcp", {}).update({
#     "context7": {"type": "remote", "url": "https://mcp.context7.com/mcp"},
#     "gh_grep":   {"type": "remote", "url": "<gh_grep mcp url>"},
# })

with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
print(f"default_agent -> orchestrator in {path}")
PY

echo "Done. Quit and restart opencode for the changes to take effect."
