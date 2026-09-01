---
description: Pick a background color, banner name and session name for this session's claude-session-banner statusLine
user-invocable: true
disable-model-invocation: true
allowed-tools: AskUserQuestion, Bash
---

The claude-session-banner statusLine shows a colored top line (the project
name) and a session tag on the second line. This command lets the user
customize both, for **this session only**, without editing any file by
hand.

`AskUserQuestion` requires 2 to 4 genuinely distinct options per question
and is only for discrete choices — never give it a question with fewer
than 2 options, and never use it to collect free text (that's what the
banner and session names are, so ask those in plain chat, not through the
tool).

1. Call `AskUserQuestion` with exactly one question, for the color only:

   - header "Color", question "¿Qué color de fondo quieres para el banner de esta sesión?", single-select, exactly these 4 options (each description names its 256-color code, which is the value to store; the user can still pick "Other" and name any other color or code, which you then map to the nearest code yourself):
     - Azul (24)
     - Verde (58)
     - Naranja (166)
     - Automático (quita cualquier color fijado antes para esta sesión)

2. In the same response, after getting the color answer, ask in plain
   chat text (not through a tool) whether they want a custom name for the
   big banner line (normally the project name) and/or a custom name for
   the session tag on the second line — and that answering "no" leaves
   both automatic. Wait for their reply before writing anything.

3. This session's id is `${CLAUDE_SESSION_ID}` — that literal value is
   already substituted above; use it as-is, do not ask the user for it and
   do not try to derive it any other way.

4. Once you have the color and the names (or "no" for either), run this,
   replacing only the `jq` filter piece described below:

   ```bash
   mkdir -p ~/.claude/session-banner-overrides
   f=~/.claude/session-banner-overrides/${CLAUDE_SESSION_ID}.json
   existing=$(cat "$f" 2>/dev/null || echo '{}')
   updated=$(echo "$existing" | jq '<filter>')
   tmp=$(mktemp)
   echo "$updated" > "$tmp"
   mv "$tmp" "$f"
   ```

   Build `<filter>` by chaining, for each of the three answers:
   - color: `.color = <code>` if a specific color was picked, or `del(.color)` if "Automático"
   - banner name: `.project_label = "<text>"` if a custom name was given, or `del(.project_label)` if not
   - session name: `.session_label = "<text>"` if a custom name was given, or `del(.session_label)` if not

   Chain them with `|`, e.g. `.color = 166 | del(.project_label) | .session_label = "qa-fix"`.
   Only touch `~/.claude/session-banner-overrides/${CLAUDE_SESSION_ID}.json` —
   never any other session's override file, and never
   `~/.claude/settings.json`.

5. Confirm back to the user in one short sentence what changed (or was
   reset to automatic). The banner updates on its next refresh, which
   happens right after this response.
