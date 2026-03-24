#!/bin/bash
# Stop hook: If WebSearch was used but store_document was not, block and remind.

INPUT=$(cat)
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path')

if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  exit 0
fi

# Check if any web search/fetch was done
HAS_WEB=$(grep -c '"WebSearch"\|"WebFetch"' "$TRANSCRIPT" 2>/dev/null || echo "0")

if [ "$HAS_WEB" -eq 0 ]; then
  exit 0
fi

# Check if store_document was called
HAS_STORE=$(grep -c 'store_document' "$TRANSCRIPT" 2>/dev/null || echo "0")

if [ "$HAS_STORE" -gt 0 ]; then
  exit 0
fi

# Web search was done but nothing stored
cat <<'EOF'
{
  "decision": "block",
  "reason": "You performed web searches but did not store the findings. Use store_document to save the key information you found to the taru knowledge graph before finishing."
}
EOF
exit 0
