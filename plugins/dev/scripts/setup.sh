#!/usr/bin/env bash
# dev plugin setup script
# Installs missing dependencies: GitHub CLI and Atlassian MCP server.
# Safe to run multiple times — skips anything already installed.

set -euo pipefail

echo ""
echo "dev plugin setup"
echo "════════════════"
echo ""

# ── GitHub CLI ───────────────────────────────────────────────────────
if command -v gh &>/dev/null; then
  echo "  ✓ GitHub CLI (gh) already installed: $(gh --version | head -1)"
else
  echo "  → Installing GitHub CLI..."
  if command -v brew &>/dev/null; then
    brew install gh
    echo "  ✓ GitHub CLI installed"
  else
    echo "  ✗ Homebrew not found. Install gh manually: https://cli.github.com/"
  fi
fi

# Check gh auth status
if command -v gh &>/dev/null; then
  if gh auth status &>/dev/null 2>&1; then
    echo "  ✓ GitHub CLI authenticated"
  else
    echo "  → GitHub CLI not authenticated. Running: gh auth login"
    gh auth login
  fi
fi

echo ""

# ── Atlassian MCP ────────────────────────────────────────────────────
atlassian_found=false
for f in "$HOME/.claude.json" "$HOME/.claude/.mcp.json" ".mcp.json" ".claude/mcp.json"; do
  if [ -f "$f" ] && grep -qi "atlassian" "$f" 2>/dev/null; then
    atlassian_found=true
    break
  fi
done

if [ "$atlassian_found" = true ]; then
  echo "  ✓ Atlassian MCP server already configured"
else
  echo "  → Adding Atlassian MCP server..."
  if command -v claude &>/dev/null; then
    claude mcp add --transport http --global atlassian https://mcp.atlassian.com/v1/mcp
    echo "  ✓ Atlassian MCP server added"
    echo "  ℹ On first use, your browser will open for Atlassian OAuth."
    echo "    Authorize access to your Atlassian site when prompted."
  else
    echo "  ✗ 'claude' CLI not found in PATH. Add the MCP server manually:"
    echo "    claude mcp add --transport http --global atlassian https://mcp.atlassian.com/v1/mcp"
  fi
fi

echo ""
echo "Setup complete. Restart Claude Code for changes to take effect."
echo ""
