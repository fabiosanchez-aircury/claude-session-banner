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
Sonnet | main | ctx 12%
```

in a different color per repo, plus the model, current git branch and
context-window usage on the second line.

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
