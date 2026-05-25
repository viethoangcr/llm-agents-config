#!/usr/bin/env bash
# setup.sh — Create symlinks from tool config dirs → central llm-agents-config repo
# Run: bash setup.sh
# Safe to re-run — checks for existing symlinks/files before acting.

set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
echo "Central repo: $REPO"

SKIPPED_PATHS=()

# ─── Helpers ───
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

copy_if_missing() {
  local src="$1" dst="$2"
  if [ -e "$dst" ]; then
    echo "  ℹ exists (skipped): $dst"
  else
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    echo "  ✓ copied: $src → $dst"
  fi
}

link_over() {
  local src="$1" dst="$2"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    echo "  → replacing file with symlink: $dst"
    rm -rf "$dst"
  fi
  link "$src" "$dst"
}

# ─── 1. OpenCode ───
echo ""
echo "=== OpenCode ==="

# Skills — each skill directory symlinked into ~/.config/opencode/skills/
for skill in "$REPO"/skills/*/; do
  name=$(basename "$skill")
  link_over "$skill" "$HOME/.config/opencode/skills/$name"
done

# Also link agentic-sdlc namespaced skills for plugin discovery
for skill in "$REPO"/skills/*/; do
  name=$(basename "$skill")
  link_over "$skill" "$HOME/.config/opencode/skills/agentic-sdlc/$name"
done

# If there are OpenCode-only skills (e.g. gh-address-comments, glab-address-comments, simplify, find-skills)
# they may already exist at ~/.config/opencode/skills/ — leave them as-is.

# Context — AGENTS.md
link "$REPO/context/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"

# Agents — symlink each agent definition
# OpenCode auto-discovers markdown agents from this directory using YAML frontmatter.
for agent in "$REPO"/agents/opencode/*.md; do
  name=$(basename "${agent%.md}")
  link_over "$agent" "$HOME/.config/opencode/agents/$name.md"
done

# User-scope agents — also symlink into .opencode/agents/ for per-project discovery
for agent in "$REPO"/agents/opencode/*.md; do
  name=$(basename "${agent%.md}")
  link_over "$agent" "$REPO/.opencode/agents/$name.md"
done

# Config — opencode.json (copy, not symlink — OpenCode may write to it)
copy_if_missing "$REPO/config/opencode.json" "$HOME/.config/opencode/opencode.json"

# Commands — symlink each command into OpenCode commands dir
for cmd in "$REPO"/commands/*.md; do
  name=$(basename "${cmd}")
  link_over "$cmd" "$HOME/.config/opencode/commands/$name"
done

echo ""
echo "=== OpenCode verification ==="
if command -v opencode >/dev/null 2>&1; then
  for name in ask chat; do
    if opencode agent list 2>/dev/null | grep -q "^$name (primary)$"; then
      echo "  ✓ OpenCode detected $name (primary)"
    else
      echo "  ⚠ OpenCode did not detect $name (primary)"
      echo "    Check for a blocking non-symlink at ~/.config/opencode/agents/$name.md"
      echo "    Restart OpenCode after setup if it was already running"
    fi
  done
  echo "  ℹ Primary agents are selected with Tab or 'opencode --agent <name>'"
else
  echo "  ℹ opencode CLI not found; skipped agent verification"
fi

# ─── 2. Claude Code ───
echo ""
echo "=== Claude Code ==="

# Skills — each skill directory symlinked into ~/.claude/skills/
for skill in "$REPO"/skills/*/; do
  name=$(basename "$skill")
  link_over "$skill" "$HOME/.claude/skills/$name"
done

# Also link agentic-sdlc namespaced skills for plugin discovery
for skill in "$REPO"/skills/*/; do
  name=$(basename "$skill")
  link_over "$skill" "$HOME/.claude/skills/agentic-sdlc/$name"
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
  link_over "$agent" "$HOME/.claude/agents/$name.md"
done

# Config — claude-settings.json (copy, not symlink — Claude Code may write to it)
copy_if_missing "$REPO/config/claude-settings.json" "$HOME/.claude/settings.json"

# ─── 3. Codex ───
echo ""
echo "=== Codex ==="

# Skills — each skill directory symlinked into ~/.agents/skills/
for skill in "$REPO"/skills/*/; do
  name=$(basename "$skill")
  link_over "$skill" "$HOME/.agents/skills/$name"
done

# Context — AGENTS.md symlink in home for Codex global context
# Codex reads AGENTS.md from project root. For global context, use ~/.codex/AGENTS.md
# or reference in config. We'll link to a discoverable location.
link "$REPO/context/AGENTS.md" "$HOME/.codex/AGENTS.md"

# Config — codex-config.toml (copy if not exists, user must edit trusted project paths)
copy_if_missing "$REPO/config/codex-config.toml" "$HOME/.codex/config.toml"
echo "  ℹ Edit ~/.codex/config.toml to add your trusted project paths"

# Agents — symlink agent .toml files into ~/.codex/agents/ (standalone agent files)
for toml in "$REPO"/agents/codex/*.toml; do
  name=$(basename "${toml%.toml}")
  link_over "$toml" "$HOME/.codex/agents/$name.toml"
done

# Agent docs — symlink .md description files alongside .toml
for doc in "$REPO"/agents/codex/*.md; do
  name=$(basename "${doc%.md}")
  link_over "$doc" "$HOME/.codex/agents/$name.md"
done

# ─── 4. Clean up old duplicates ───
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
