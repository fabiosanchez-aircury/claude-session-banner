#!/bin/bash
# Installs the session banner as this machine's Claude Code statusLine.
# Merges into ~/.claude/settings.json without touching other keys, and
# backs up the existing file first.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATUSLINE_PATH="$SCRIPT_DIR/statusline.sh"
SETTINGS_FILE="$HOME/.claude/settings.json"

chmod +x "$STATUSLINE_PATH"

mkdir -p "$HOME/.claude"
if [ ! -f "$SETTINGS_FILE" ]; then
    echo '{}' >"$SETTINGS_FILE"
fi

cp "$SETTINGS_FILE" "$SETTINGS_FILE.bak-$(date +%Y%m%dT%H%M%S)"

TMP=$(mktemp)
jq --arg cmd "$STATUSLINE_PATH" \
    '.statusLine = {"type": "command", "command": $cmd}' \
    "$SETTINGS_FILE" >"$TMP"
mv "$TMP" "$SETTINGS_FILE"

echo "Installed. statusLine now points to $STATUSLINE_PATH"
echo "A backup of the previous settings.json was saved alongside it."
echo "Open or switch to any Claude Code session to see the banner."
