#!/bin/bash
# Claude Code statusLine script: shows a colored, clickable banner naming
# the current project/board (from the git origin remote, falling back to
# the folder name), plus a per-session accent so several sessions open in
# the same repo are still distinguishable.
set -euo pipefail

input=$(cat)

DIR=$(jq -r '.workspace.current_dir // .cwd // empty' <<<"$input")
REPO_NAME=$(jq -r '.workspace.repo.name // empty' <<<"$input")
REPO_HOST=$(jq -r '.workspace.repo.host // empty' <<<"$input")
REPO_OWNER=$(jq -r '.workspace.repo.owner // empty' <<<"$input")
MODEL=$(jq -r '.model.display_name // empty' <<<"$input")
PCT=$(jq -r '.context_window.used_percentage // empty' <<<"$input" | cut -d. -f1)
PR_URL=$(jq -r '.pr.url // empty' <<<"$input")
SESSION_ID=$(jq -r '.session_id // empty' <<<"$input")
SESSION_NAME=$(jq -r '.session_name // empty' <<<"$input")

# Per-session choices made through the /banner command, keyed by session id.
OVERRIDE_FILE="$HOME/.claude/session-banner-overrides/${SESSION_ID}.json"
OVERRIDE_COLOR=""
OVERRIDE_PROJECT_LABEL=""
OVERRIDE_SESSION_LABEL=""
if [ -n "$SESSION_ID" ] && [ -f "$OVERRIDE_FILE" ]; then
    OVERRIDE_COLOR=$(jq -r '.color // empty' "$OVERRIDE_FILE" 2>/dev/null || true)
    OVERRIDE_PROJECT_LABEL=$(jq -r '.project_label // empty' "$OVERRIDE_FILE" 2>/dev/null || true)
    OVERRIDE_SESSION_LABEL=$(jq -r '.session_label // empty' "$OVERRIDE_FILE" 2>/dev/null || true)
fi

NAME="$REPO_NAME"
if [ -z "$NAME" ]; then
    NAME=$(basename "${DIR:-unknown}")
fi
DEFAULT_LABEL=$(tr '[:lower:]' '[:upper:]' <<<"${NAME//[-_]/ }")
LABEL="${CLAUDE_BANNER_LABEL:-${OVERRIDE_PROJECT_LABEL:-$DEFAULT_LABEL}}"

# Deterministic background color per project name, picked from a palette of
# mid-dark 256-color codes that stay readable under bold white text. This
# needs no per-project mapping: any repo name lands on a stable color.
PALETTE=(24 25 26 30 33 54 58 62 88 94 125 130 160 166)
HASH=$(cksum <<<"$NAME" | cut -d' ' -f1)
BG="${CLAUDE_BANNER_COLOR:-${OVERRIDE_COLOR:-${PALETTE[$((HASH % ${#PALETTE[@]}))]}}}"

# A small second color, hashed from the session id, accents the session
# line so two sessions in the same project are still visually different.
SESSION_KEY="${SESSION_NAME:-$SESSION_ID}"
ACCENT=37
if [ -n "$SESSION_KEY" ]; then
    SHASH=$(cksum <<<"$SESSION_KEY" | cut -d' ' -f1)
    ACCENT=${PALETTE[$((SHASH % ${#PALETTE[@]}))]}
fi
SESSION_LABEL="${OVERRIDE_SESSION_LABEL:-$SESSION_NAME}"

RESET='\033[0m'
BANNER_TEXT="\033[48;5;${BG}m\033[97;1m  ${LABEL}  ${RESET}"

# Clicking the banner opens the open PR when there is one, otherwise the
# repo's homepage; override with CLAUDE_BANNER_URL, or leave the banner
# plain when neither is known.
LINK_URL="${CLAUDE_BANNER_URL:-}"
if [ -z "$LINK_URL" ] && [ -n "$PR_URL" ]; then
    LINK_URL="$PR_URL"
elif [ -z "$LINK_URL" ] && [ -n "$REPO_HOST" ] && [ -n "$REPO_OWNER" ] && [ -n "$REPO_NAME" ]; then
    LINK_URL="https://${REPO_HOST}/${REPO_OWNER}/${REPO_NAME}"
fi

if [ -n "$LINK_URL" ]; then
    BANNER="\033]8;;${LINK_URL}\a${BANNER_TEXT}\033]8;;\a"
else
    BANNER="$BANNER_TEXT"
fi

BRANCH=""
if [ -n "$DIR" ] && git -C "$DIR" rev-parse --git-dir >/dev/null 2>&1; then
    BR=$(git -C "$DIR" branch --show-current 2>/dev/null || true)
    [ -n "$BR" ] && BRANCH=" | ${BR}"
fi

SESSION_TAG=""
if [ -n "$SESSION_LABEL" ]; then
    SESSION_TAG=" | \033[38;5;${ACCENT}m● ${SESSION_LABEL}${RESET}"
elif [ -n "$SESSION_ID" ]; then
    SESSION_TAG=" | \033[38;5;${ACCENT}m● ${SESSION_ID:0:7}${RESET}"
fi

printf '%b\n' "$BANNER"
printf '%b\n' "${MODEL:-?}${BRANCH} | ctx ${PCT:-0}%${SESSION_TAG}"
