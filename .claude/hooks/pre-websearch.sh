#!/bin/bash
# PreToolUse hook: Before WebSearch, check if search_graph was already called.
# If not, block and tell Claude to search taru first.

INPUT=$(cat)
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path')

if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  exit 0
fi

# Check if search_graph was already called in this conversation
if grep -q 'store_document\|search_graph' "$TRANSCRIPT" 2>/dev/null; then
  # Already searched taru, allow web search
  exit 0
fi

# Block: tell Claude to search taru first
cat <<'EOF'
{
  "decision": "block",
  "reason": "Search the taru knowledge graph first (search_graph) before using web search. The answer might already be stored."
}
EOF
exit 0
