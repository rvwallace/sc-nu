# Changelog

This file documents all notable changes to the `sc-nu` configuration.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### 2026-09-27

- Updated `README.md` with the project history and links to the `sc-zsh`, `toolbox`, and `tmux-conf` repositories

### 2026-09-26

- Trimmed route-table lines before parsing in `ip.if` to prevent blank output from `last`

### 2026-09-25

- Disabled OSC 8 clickable links (`clickable_links: false` in `$env.config.ls` and `osc8: false` in `$env.config.shell_integration`) due to an upstream parser issue in `ansi-to-tui` (used by `tmux-snaglord`), where OSC 8 hyperlink sequences terminated by standard ECMA-48 `ST` (`\x1b\`) cause subsequent filenames, table columns, and borders in directory listings to be swallowed and omitted from TUI rendering
- Added documentation in `README.md` and `docs/SNAGLORD_HYPERLINK_ISSUE.md` detailing the upstream parser issue and mitigation
