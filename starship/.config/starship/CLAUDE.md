# Starship Prompt

Cross-shell prompt with contextual information on the right side.

## Config Location

```bash
~/.config/starship/starship.toml
```

## Prompt Layout

- **Left**: `$directory` + `$character` (minimal)
- **Right**: `$all` (everything else - git, languages, time, etc.)

## Key Modules

| Module | Purpose |
|--------|---------|
| `character` | Shows `➜` success, `✗` error, `` vim normal mode |
| `directory` | Fish-style truncation (`~/d/p/repo`), git root highlighted |
| `cmd_duration` | Shows elapsed time for commands >2s |
| `status` | Exit codes with pipestatus for `cmd1 | cmd2` failures |
| `git_branch` | Branch name with remote tracking |
| `git_status` | Dirty state (`?!+`), ahead/behind (`⇡⇣`) |
| `git_metrics` | Line changes (`+42 -17`) |
| `direnv` | Shows `▲` when direnv has loaded env |
| `time` | Current time (HH:MM) |

## Desktop Notifications

`cmd_duration` sends desktop notifications for commands taking >45s. Grant notification permissions to your terminal app if not working.

## Performance Notes

- `git_metrics` has slight overhead on large repos - disable first if prompt is slow
- `command_timeout = 1000` kills slow module lookups after 1s

## Theme

Uses `catppuccin_mocha` palette defined inline in the config.

## Docs

Local cache: `docs:search_docs query="starship"`
Online: https://starship.rs/config/
