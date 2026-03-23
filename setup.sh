#!/usr/bin/env bash
set -euo pipefail

# taru MCP setup script
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/arupa-inc/taru-mcp/main/setup.sh | bash

URL="https://taru-api.arupa.io"

echo ""
echo "  🌳 taru MCP Setup"
echo ""

# 1. Ask project folder name
read -rp "Project folder name: " FOLDER
if [ -z "$FOLDER" ]; then
  echo "Error: folder name is required"
  exit 1
fi

if [ -d "$FOLDER" ]; then
  echo "==> Directory '$FOLDER' already exists, using it."
else
  mkdir -p "$FOLDER"
  echo "==> Created '$FOLDER'"
fi
cd "$FOLDER"

# 2. Ask client type
echo ""
echo "Which AI client do you use?"
echo "  1) Claude Code"
echo "  2) Codex"
echo "  3) Not sure (copies both CLAUDE.md and AGENTS.md)"
echo ""
read -rp "Choose [1/2/3]: " CLIENT_CHOICE

case "$CLIENT_CHOICE" in
  1) CLIENT="claude" ;;
  2) CLIENT="codex" ;;
  *) CLIENT="both" ;;
esac

# 3. Ask token (skippable)
echo ""
read -rp "Workspace token (xxv_..., press Enter to add later): " TOKEN

# Check npm
if ! command -v npm &>/dev/null; then
  echo "Error: 'npm' not found. Install Node.js first."
  exit 1
fi

# Init & install
if [ ! -f "package.json" ]; then
  echo "==> Initializing package.json..."
  npm init -y --silent > /dev/null 2>&1
fi

echo "==> Installing taru-mcp..."
npm install taru-mcp --silent

# Copy agent files
copy_agent_file() {
  local file="$1"
  if [ -f "$file" ]; then
    echo "==> $file already exists, appending taru instructions..."
    echo "" >> "$file"
    cat "node_modules/taru-mcp/samples/$file" >> "$file"
  else
    cp "node_modules/taru-mcp/samples/$file" "./$file"
    echo "==> Created $file"
  fi
}

if [ "$CLIENT" = "claude" ]; then
  copy_agent_file "CLAUDE.md"
elif [ "$CLIENT" = "codex" ]; then
  copy_agent_file "AGENTS.md"
else
  copy_agent_file "CLAUDE.md"
  copy_agent_file "AGENTS.md"
fi

# Register MCP server
register_mcp() {
  local cli="$1"
  local token_args=""
  if [ -n "$TOKEN" ]; then
    token_args=" --token $TOKEN"
  fi

  if command -v "$cli" &>/dev/null; then
    echo "==> Registering MCP server with $cli..."
    $cli mcp add taru -- npx taru-mcp --url "$URL"$token_args
  else
    echo "==> '$cli' not found, skipping MCP registration."
    echo "    Run this later: $cli mcp add taru -- npx taru-mcp --url $URL$token_args"
  fi
}

if [ "$CLIENT" = "claude" ]; then
  register_mcp "claude"
elif [ "$CLIENT" = "codex" ]; then
  register_mcp "codex"
else
  register_mcp "claude"
  register_mcp "codex"
fi

echo ""
echo "  ✅ Setup complete!"
echo ""
echo "  Project: $(pwd)"
[ "$CLIENT" = "claude" ] || [ "$CLIENT" = "both" ] && echo "  Agent file: ./CLAUDE.md"
[ "$CLIENT" = "codex" ] || [ "$CLIENT" = "both" ] && echo "  Agent file: ./AGENTS.md"
[ -n "$TOKEN" ] && echo "  Token: configured" || echo "  Token: not set yet (add via settings)"
echo ""
echo "  Open this folder in your AI client to start growing the tree."
echo ""
