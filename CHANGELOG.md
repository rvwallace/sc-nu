# Changelog

This file documents all notable changes to the `sc-nu` configuration.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### 2026-09-29

- Use `~/.config/nushell` as the canonical configuration directory on macOS and Linux
- Migrate existing macOS Nushell data from `~/Library/Application Support/nushell` and keep that path as a compatibility symlink
- Add `doctor.sh` for read-only installation checks and make `setup.sh` repair existing installs with timestamped backups
- Load the toolbox companion modules from the private `local/post.nu` file
- Derive the `sc-nu` module path from `$nu.config-path` and keep the machine-specific toolbox path in private `local/post.nu`
- Guard macOS-only commands and use XDG paths for history import and Linux route commands
- Move organization-specific GitLab search code to private `local/post.nu`

### 2026-09-27

- Updated `README.md` with the project history and links to the `sc-zsh`, `toolbox`, and `tmux-conf` repositories

### 2026-09-26

- Trimmed route-table lines before parsing in `ip.if` to prevent blank output from `last`

### 2026-09-25

- Disabled OSC 8 clickable links (`clickable_links: false` in `$env.config.ls` and `osc8: false` in `$env.config.shell_integration`) due to an upstream parser issue in `ansi-to-tui` (used by `tmux-snaglord`), where OSC 8 hyperlink sequences terminated by standard ECMA-48 `ST` (`\x1b\`) cause subsequent filenames, table columns, and borders in directory listings to be swallowed and omitted from TUI rendering
- Added documentation in `README.md` and `docs/SNAGLORD_HYPERLINK_ISSUE.md` detailing the upstream parser issue and mitigation
