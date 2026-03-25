#!/usr/bin/env bash
# dev plugin dependency check
# Runs on SessionStart to ensure prerequisites are available.
# Exits silently (0) if everything is fine.
# Prints a setup message and exits 0 if something is missing
# (we still exit 0 so we don't block the session).

set -euo pipefail

missing=()

# ── Check 1: GitHub CLI (gh) ────────────────────────────────────────
if ! command -v gh &>/dev/null; then
  missing+=("gh")
fi

# ── Check 2: Atlassian MCP server ───────────────────────────────────
# Look for "atlassian" in any of the known MCP config locations.
atlassian_found=false
for f in "$HOME/.claude.json" "$HOME/.claude/.mcp.json" ".mcp.json" ".claude/mcp.json"; do
  if [ -f "$f" ] && grep -qi "atlassian" "$f" 2>/dev/null; then
    atlassian_found=true
    break
  fi
done

if [ "$atlassian_found" = false ]; then
  missing+=("atlassian-mcp")
fi

# ── Check 3: trello-cli ──────────────────────────────────────────
if ! command -v trello &>/dev/null; then
  missing+=("trello-cli")
fi

# ── All good ─────────────────────────────────────────────────────────
if [ ${#missing[@]} -eq 0 ]; then
  exit 0
fi

# ── Print setup instructions ─────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  dev plugin: missing dependencies                           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

for dep in "${missing[@]}"; do
  case "$dep" in
    gh)
      echo "  ✗ GitHub CLI (gh) — required for /dev:pr"
      echo ""
      echo "    Install:   brew install gh"
      echo "    Authenticate:  gh auth login"
      echo ""
      ;;
    atlassian-mcp)
      echo "  ✗ Atlassian MCP server — required for /dev:jira"
      echo ""
      echo "    Install:   claude mcp add --transport http --global atlassian https://mcp.atlassian.com/v1/mcp"
      echo "    Auth:      On first use, your browser will open for Atlassian OAuth"
      echo "    Verify:    claude mcp list  (should show 'atlassian')"
      echo ""
      ;;
    trello-cli)
      echo "  ✗ trello-cli — required for /dev:trello"
      echo ""
      echo "    Install:   npm install -g trello-cli"
      echo "    Auth:      trello auth:api-key YOUR_KEY && trello auth:token YOUR_TOKEN"
      echo "    API key:   https://trello.com/power-ups/admin"
      echo "    Sync:      trello sync"
      echo ""
      ;;
  esac
done

echo "  After installing, restart Claude Code for changes to take effect."
echo ""

exit 0
