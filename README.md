# claude-session-banner

A Claude Code [statusLine](https://code.claude.com/docs/en/statusline.md)
that shows a colored banner naming the current project, so that several
Claude Code terminal sessions open at once — one in `link-go`, one in
`tasks`, one in any other board's repo — are distinguishable at a glance
instead of looking identical.

It needs no per-project setup: it reads the project name from the current
session's git origin remote (`workspace.repo.name`, falling back to the
folder name outside a git repo) and picks a background color deterministic
per name from a fixed palette, so any repo — present or future — gets a
stable, distinct color with nothing to configure.

## What it looks like

```
  LINK GO
Sonnet | main | ctx 12% | ● qa-fix
```

in a different color per repo, plus the model, current git branch,
context-window usage and a session tag on the second line.

## Clickable

The banner is a clickable link (Cmd+click on macOS, Ctrl+click on
Windows/Linux, in terminals that support it — iTerm2, Kitty, WezTerm, the
VS Code integrated terminal). It opens:

1. The session's open pull request, if there is one, or otherwise
2. The repository's homepage, derived from the git origin remote, or
   otherwise
3. Nothing — the banner stays plain text when neither is known (for
   example, outside a GitHub/GitLab-backed repo).

## Telling sessions apart within the same project

The `● tag` on the second line is a per-session accent, colored from a
hash of the session id so it stays stable but differs between sessions:

* Run `/rename <name>` in a session and that name shows up as the tag —
  the quickest way to make a specific session self-explanatory (e.g.
  `/rename qa-fix`).
* Leave it unrenamed and you still get a colored dot plus the first
  characters of the session id, enough to tell two sessions in the same
  repo apart even without naming them.
* Run `/banner` for full control — see below.

## `/banner`: pick a color and names for this session

A terminal hyperlink can only ever open a URL — it cannot pop up a color
picker or a text field in place, so "click to customize" isn't something
any terminal supports. `/banner` is the practical equivalent: type it in
a session and it asks you (through Claude Code's own picker UI) for:

* a background color, from a fixed palette,
* a custom name for the big banner line (normally the project name), and
* a custom name for the session tag on the second line,

each answerable in one keypress, or "Other" to type your own text. It
writes the choice to
`~/.claude/session-banner-overrides/<session_id>.json`, scoped to that
one session only — every other session, in this project or any other,
is unaffected. Picking "Automático" for any of the three clears that
part of the override again.

The command is installed as a Claude Code skill at
`~/.claude/skills/banner`, symlinked to `skills/banner/` in this
checkout by `install.sh`, so it works in every project, the same way the
statusLine itself does.

## Per-session overrides

Set these before starting `claude` in a given terminal to override what
that one session shows, on top of everything above:

| Variable | Overrides |
| --- | --- |
| `CLAUDE_BANNER_LABEL` | The big banner text |
| `CLAUDE_BANNER_COLOR` | The banner's background color (a 256-color code) |
| `CLAUDE_BANNER_URL` | Where clicking the banner goes |

```bash
CLAUDE_BANNER_LABEL="OVERBOARDS · TASKS QA" CLAUDE_BANNER_COLOR=208 claude
```

Since they're plain environment variables, they apply only to the shell
(and the `claude` process it starts) where you export them — a natural
fit for "this one terminal tab is special."

## Install

Requires `jq` (`sudo apt install jq` / `brew install jq`).

```bash
./install.sh
```

This adds a `statusLine` entry to `~/.claude/settings.json`, pointing at
`statusline.sh` in this checkout — it merges in without touching any other
setting already there, and backs up the file first. Since it's a global
setting, it applies to every Claude Code session on this machine,
whichever repo it's opened in.

Switch to (or start) any Claude Code session to see it take effect.

## Uninstall

```bash
./uninstall.sh
```

Removes only the `statusLine` key, leaving the rest of your settings
untouched.

## Customizing the palette

Edit the `PALETTE` array in `statusline.sh` — any 256-color codes. Colors
are assigned by hashing the project name, so editing the list reshuffles
every project's color; there's no per-project mapping to maintain.
