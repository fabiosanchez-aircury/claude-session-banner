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

1. Call `AskUserQuestion` once with three questions:

   - header "Color", question "¿Qué color de fondo quieres para el banner de esta sesión?", single-select, options (each description names its 256-color code, which is the value to store):
     - Azul (24)
     - Verde azulado (30)
     - Morado (54)
     - Verde (58)
     - Fucsia (125)
     - Naranja (166)
     - Rojo (160)
     - Automático (quita cualquier color fijado antes para esta sesión)

   - header "Nombre banner", question "¿Nombre para la línea grande del banner (normalmente el nombre del proyecto)?", single-select, options:
     - Dejar automático (usa el nombre del proyecto)
     (the user can also pick "Other" to type any custom text, which becomes the literal banner text)

   - header "Nombre sesión", question "¿Nombre para identificar esta sesión en la segunda línea?", single-select, options:
     - Dejar automático (usa /rename si existe, si no un id corto)
     (again "Other" lets them type any custom text)

2. This session's id is `${CLAUDE_SESSION_ID}` — that literal value is
   already substituted above; use it as-is, do not ask the user for it and
   do not try to derive it any other way.

3. Run this, replacing only the three `jq` filter pieces described below:

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
   - banner name: `.project_label = "<text>"` if custom text was given, or `del(.project_label)` if "Dejar automático"
   - session name: `.session_label = "<text>"` if custom text was given, or `del(.session_label)` if "Dejar automático"

   Chain them with `|`, e.g. `.color = 166 | del(.project_label) | .session_label = "qa-fix"`.
   Only touch `~/.claude/session-banner-overrides/${CLAUDE_SESSION_ID}.json` —
   never any other session's override file, and never
   `~/.claude/settings.json`.

4. Confirm back to the user in one short sentence what changed (or was
   reset to automatic). The banner updates on its next refresh, which
   happens right after this response.
