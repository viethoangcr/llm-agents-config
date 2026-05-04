#!/usr/bin/env bash
# setup.sh — Create symlinks from tool config dirs → central llm-agents-config repo
# Run: bash setup.sh
# Safe to re-run — checks for existing symlinks/files before acting.

set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
echo "Central repo: $REPO"

SKIPPED_PATHS=()

# ─── Helper ───
link() {
  local src="$1" dst="$2"
  if [ -L "$dst" ]; then
    local current
    current="$(readlink "$dst")"
    if [ "$current" = "$src" ]; then
      echo "  ↻ symlink exists: $dst"
    else
      ln -sfn "$src" "$dst"
      echo "  ↻ updated symlink: $dst → $src"
    fi
  elif [ -e "$dst" ]; then
    echo "  ⚠ skipping (file exists, not symlink): $dst"
    SKIPPED_PATHS+=("$dst")
  else
    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
    echo "  ✓ linked: $dst → $src"
  fi
}

# ─── 1. OpenCode ───
echo ""
echo "=== OpenCode ==="

# Skills — each skill directory symlinked into ~/.config/opencode/skills/
for skill in "$REPO"/skills/*/; do
  name=$(basename "$skill")
  link "$skill" "$HOME/.config/opencode/skills/$name"
done

# Also link agentic-sdlc namespaced skills for plugin discovery
for skill in "$REPO"/skills/*/; do
  name=$(basename "$skill")
  link "$skill" "$HOME/.config/opencode/skills/agentic-sdlc/$name"
done

# If there are OpenCode-only skills (e.g. gh-address-comments, glab-address-comments, simplify, find-skills)
# they may already exist at ~/.config/opencode/skills/ — leave them as-is.

# Context — AGENTS.md
link "$REPO/context/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"

# Agents — symlink each agent definition
# OpenCode auto-discovers markdown agents from this directory using YAML frontmatter.
for agent in "$REPO"/agents/opencode/*.md; do
  name=$(basename "${agent%.md}")
  link "$agent" "$HOME/.config/opencode/agents/$name.md"
done

echo ""
echo "=== OpenCode verification ==="
if command -v opencode >/dev/null 2>&1; then
  if opencode agent list 2>/dev/null | grep -q '^ask (primary)$'; then
    echo "  ✓ OpenCode detected ask (primary)"
  else
    echo "  ⚠ OpenCode did not detect ask (primary)"
    echo "    Check for a blocking non-symlink at ~/.config/opencode/agents/ask.md"
    echo "    Restart OpenCode after setup if it was already running"
  fi
  echo "  ℹ Primary agents are selected with Tab or 'opencode --agent ask'"
else
  echo "  ℹ opencode CLI not found; skipped agent verification"
fi

# ─── 2. Claude Code ───
echo ""
echo "=== Claude Code ==="

# Skills — each skill directory symlinked into ~/.claude/skills/
for skill in "$REPO"/skills/*/; do
  name=$(basename "$skill")
  link "$skill" "$HOME/.claude/skills/$name"
done

# Also link agentic-sdlc namespaced skills for plugin discovery
for skill in "$REPO"/skills/*/; do
  name=$(basename "$skill")
  link "$skill" "$HOME/.claude/skills/agentic-sdlc/$name"
done

# Context — CLAUDE.md (imports AGENTS.md via @ syntax)
if [ -L "$HOME/.claude/CLAUDE.md" ]; then
  echo "  ↻ symlink exists: ~/.claude/CLAUDE.md"
elif [ -f "$HOME/.claude/CLAUDE.md" ]; then
  echo "  ⚠ ~/.claude/CLAUDE.md already exists — append this line manually:"
  echo "    @~/Workspace/personal/llm-agents-config/context/AGENTS.md"
else
  cat > "$HOME/.claude/CLAUDE.md" << 'CLAUDE_EOF'
@~/Workspace/personal/llm-agents-config/context/AGENTS.md
CLAUDE_EOF
  echo "  ✓ created ~/.claude/CLAUDE.md with @import"
fi

# Agents — symlink each agent definition
for agent in "$REPO"/agents/claude/*.md; do
  name=$(basename "${agent%.md}")
  link "$agent" "$HOME/.claude/agents/$name.md"
done

# ─── 3. Codex ───
echo ""
echo "=== Codex ==="

# Skills — each skill directory symlinked into ~/.agents/skills/
for skill in "$REPO"/skills/*/; do
  name=$(basename "$skill")
  link "$skill" "$HOME/.agents/skills/$name"
done

# Context — AGENTS.md symlink in home for Codex global context
# Codex reads AGENTS.md from project root. For global context, use ~/.codex/AGENTS.md
# or reference in config. We'll link to a discoverable location.
link "$REPO/context/AGENTS.md" "$HOME/.codex/AGENTS.md"

# Agent config — print TOML references (Codex needs actual file, not symlink for TOML)
for toml in "$REPO"/agents/codex/*.toml; do
  name=$(basename "${toml%.toml}")
  if [ ! -f "$HOME/.codex/config.toml" ] || ! grep -q "$name" "$HOME/.codex/config.toml" 2>/dev/null; then
    echo "  ℹ Add the following to ~/.codex/config.toml for the $name agent:"
    echo ""
    cat "$toml"
    echo ""
  fi
done

# ─── 4. Project-level setup ───
echo ""
echo "=== Project-level (per-repo) ==="
echo "For each project, symlink or copy AGENTS.md to the project root:"
echo ""
echo "  ln -sf $REPO/context/AGENTS.md /path/to/project/AGENTS.md"
echo ""
echo "Or add to opencode.json in each project:"
echo ""
echo '  { "instructions": ["~/Workspace/personal/llm-agents-config/context/AGENTS.md"] }'
echo ""

# ─── 5. Clean up old duplicates ───
echo "=== Cleanup ==="
echo ""
echo "After verifying the symlinks work, you may remove old duplicate skill directories:"
echo "  rm -rf ~/.claude/skills/brainstorming ~/.claude/skills/building-tasks ..."
echo "  rm -rf ~/.config/opencode/skills/agentic-sdlc/brainstorming ..."
echo ""
echo "This script only creates symlinks — it does NOT delete existing files."
echo "Review first, then clean up manually."
if [ ${#SKIPPED_PATHS[@]} -gt 0 ]; then
  echo ""
  echo "Skipped existing non-symlink paths:"
  for path in "${SKIPPED_PATHS[@]}"; do
    echo "  - $path"
  done
fi
echo ""
echo "✅ Setup complete!"
