#!/bin/bash
# Removes the statusLine entry this tool installed, leaving every other
# ~/.claude/settings.json key untouched.
set -euo pipefail

SETTINGS_FILE="$HOME/.claude/settings.json"
SKILL_LINK="$HOME/.claude/skills/banner"

if [ -L "$SKILL_LINK" ]; then
    rm "$SKILL_LINK"
    echo "Removed the /banner command link at $SKILL_LINK"
fi

if [ ! -f "$SETTINGS_FILE" ]; then
    echo "No $SETTINGS_FILE found; nothing to do."
    exit 0
fi

cp "$SETTINGS_FILE" "$SETTINGS_FILE.bak-$(date +%Y%m%dT%H%M%S)"

TMP=$(mktemp)
jq 'del(.statusLine)' "$SETTINGS_FILE" >"$TMP"
mv "$TMP" "$SETTINGS_FILE"

echo "statusLine removed from $SETTINGS_FILE (backup saved alongside it)."
echo "Per-session overrides in ~/.claude/session-banner-overrides/ were left in place."
