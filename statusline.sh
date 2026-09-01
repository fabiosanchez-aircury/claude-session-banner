#!/bin/bash
# Claude Code statusLine script: shows a colored banner naming the current
# project/board (from the git origin remote, falling back to the folder
# name) so sessions open in different repos are distinguishable at a glance.
set -euo pipefail

input=$(cat)

DIR=$(jq -r '.workspace.current_dir // .cwd // empty' <<<"$input")
REPO_NAME=$(jq -r '.workspace.repo.name // empty' <<<"$input")
MODEL=$(jq -r '.model.display_name // empty' <<<"$input")
PCT=$(jq -r '.context_window.used_percentage // empty' <<<"$input" | cut -d. -f1)

NAME="$REPO_NAME"
if [ -z "$NAME" ]; then
    NAME=$(basename "${DIR:-unknown}")
fi
LABEL=$(tr '[:lower:]' '[:upper:]' <<<"${NAME//[-_]/ }")

# Deterministic background color per project name, picked from a palette of
# mid-dark 256-color codes that stay readable under bold white text. This
# needs no per-project mapping: any repo name lands on a stable color.
PALETTE=(24 25 26 30 33 54 58 62 88 94 125 130 160 166)
HASH=$(cksum <<<"$NAME" | cut -d' ' -f1)
BG=${PALETTE[$((HASH % ${#PALETTE[@]}))]}

RESET='\033[0m'
BANNER="\033[48;5;${BG}m\033[97;1m  ${LABEL}  ${RESET}"

BRANCH=""
if [ -n "$DIR" ] && git -C "$DIR" rev-parse --git-dir >/dev/null 2>&1; then
    BR=$(git -C "$DIR" branch --show-current 2>/dev/null || true)
    [ -n "$BR" ] && BRANCH=" | ${BR}"
fi

echo -e "$BANNER"
echo -e "${MODEL:-?}${BRANCH} | ctx ${PCT:-0}%"
