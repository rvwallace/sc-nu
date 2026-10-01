# sc-nu: Modular Nushell Configuration

`sc-nu` is a modular Nushell configuration system that grew from the [`sc-zsh`](https://github.com/rvwallace/sc-zsh) configuration. It runs beside `sc-zsh`.

- **Cold startup time**: About **16 ms**, compared with about **170 ms** in tuned Zsh. This is more than a 90 percent reduction.
- **Structure**: Separate modules, typed Nushell pipelines, SQLite history, and tool integrations.
- **[Toolbox modules](https://github.com/rvwallace/toolbox)**: Nushell modules for AWS (`aws.env`), Kubernetes (`k.env`), Chef (`chef.env`), Git (`git.cdroot`), Tmux (`tp`), and Yazi (`y`).
- **Completions and integrations**: Carapace, Starship, and Zoxide.
- **Guides**: A [Migration Cheatsheet](docs/CHEATSHEET.md) and a [DevOps Data Cookbook](docs/DATA_COOKBOOK.md).

---

## Documentation and Guides

- **[Nushell Quick Reference and Migration Cheatsheet](docs/CHEATSHEET.md)**
  - Compare Zsh and Nushell concepts with a Rosetta Stone.
  - Review string interpolation (`$"..."`) and quoting rules.
  - Review pipes, redirection, and subexpressions.
- **[DevOps Data Manipulation Cookbook](docs/DATA_COOKBOOK.md)**
  - Query AWS with `describe-instances`, `sts`, `s3`, and `security-groups`.
  - Query Chef with `search node -F json`, `run_list`, and node attributes.
  - Query Kubernetes with `kubectl get -o json`.
  - Use `select`, `where`, `flatten`, `transpose`, `explore`, and `to md/json/yaml`.
- **[Changelog](CHANGELOG.md)**: Read the configuration history.
- **[Snaglord Hyperlink Issue Notes](docs/SNAGLORD_HYPERLINK_ISSUE.md)**: Read about the `ansi-to-tui` OSC 8 parser limits and the workaround.

## Architecture and Directory Structure

```
~/silentcastle/projects/sc-nu/
├── env.nu                 # Environment variables, PATH deduplication, tool caching
├── config.nu              # Core options, keybindings, hooks, completion bridge
├── setup.sh               # Install and repair the configuration
├── doctor.sh               # Check the installation without changing files
├── CHANGELOG.md           # Release history and configuration changes
├── docs/                  # Cheatsheet, cookbook, and issue notes
├── modules/
│   ├── aliases.nu         # General aliases (eza, bat, python, brew, tmux)
│   └── commands.nu        # Custom commands (ql, rm.dstore, ip.wan, ip.if, ip.gw)
└── .gitignore             # Local private files and history databases
```

### Local Customizations (Untracked)

- `~/.config/nushell/local/pre.nu`: Private environment variables, tokens, and API keys. `env.nu` loads this file early.
- `~/.config/nushell/local/post.nu`: Machine-specific commands and overrides. `config.nu` loads this file late during startup.

## Key Features

### 1. [Toolbox Companion Modules](https://github.com/rvwallace/toolbox)

`sc-nu` imports Nushell companion modules from the [toolbox repository](https://github.com/rvwallace/toolbox). Set the toolbox path in the private `local/post.nu` file:

```nu
export use /path/to/toolbox/shell/init.nu *
```

The module import makes exported Toolbox commands, including `toolboxctl`, available in the interactive session. Keep the checkout path in the private file; do not add a machine-specific path to this repository.

- **`aws.env`**: Switch AWS profiles and regions. The command uses `aws-env` and exports variables with `def --env`.
- **`k.env`**: Select a Kubernetes configuration from `~/.kube` with `fzf` and a `bat` preview. Use `context`, `ns`, and `clear` to manage the session.
- **`chef.env`**: Set a Chef environment with `fzf` and use `clear`, `show`, and `list`.
- **`git.cdroot`**: Change to the root directory of the current Git repository.
- **`tp`**: Run a command in a Tmux display popup.
- **`y`**: Run Yazi and change to the selected directory when Yazi exits.
- **`terraform`**: Run `tfswitch` when the directory changes through Nushell's `env_change.PWD` hook.

### Terraform Version Switching

When `tfswitch` is installed, the PWD hook runs it when the new directory contains
`.terraform-version`, `.tfswitchrc`, or `versions.tf`. To keep the hook's
non-interactive execution on the same Terraform binary path as other shells,
configure the managed binary in `~/.tfswitch.toml`:

```toml
bin = "$HOME/.local/bin/terraform"
```

The hook uses the configured `bin` value when present. Without the file, it
falls back to the Terraform executable resolved on `PATH`, then
`~/.local/bin/terraform`. Run `./doctor.sh` to check the configuration; a
missing `~/.tfswitch.toml` is reported as a warning when `tfswitch` is installed.

### 2. Application Integrations

The configuration generates integration files in Nushell's cache directory at startup. It stores a version sidecar next to each generated file and regenerates the file when the tool, Nushell, or generation settings change:

- **Starship**: A fast prompt that renders in Nushell.
- **Carapace**: A completion bridge for Git, Docker, Kubectl, AWS, GitHub CLI, and other commands.
- **Zoxide**: A directory jumper available as `z` and `zi`. Native `cd` stays
  available for normal path navigation and directory-aware Tab completion;
  Zoxide's `PWD` hook still learns directories entered with `cd` automatically.

### 3. Keybindings (Reedline)

- `Ctrl-O`: Open the current command line in `$EDITOR` (`nvim`).
- `Ctrl-R`: Open the interactive history search menu.
- `Tab`: Open the completion menu.
- `Up` / `Down`: Search the history with the current input.

### 4. Terminal and [Multiplexer Compatibility](https://github.com/rvwallace/tmux-conf)

`$env.config.ls.clickable_links` and `$env.config.shell_integration.osc8` are set to `false`. This avoids an upstream parser bug in `ansi-to-tui`, which `tmux-snaglord` uses. The bug can swallow table columns and file names after OSC 8 sequences that end with the standard ECMA-48 `ST` (`\x1b\`) sequence.

File colors (`LS_COLORS`), file sizes, and table borders remain active. See the [Snaglord Hyperlink Issue Notes](docs/SNAGLORD_HYPERLINK_ISSUE.md) for details.

## Installation and Setup

1. Install Nushell by using the [official Nushell installation guide](https://www.nushell.sh/book/installation.html). The guide lists current packages, pre-built binaries, and source installation methods for each operating system. Distribution repositories can provide older Nushell versions.

2. Install the configuration:

   ```bash
   cd ~/silentcastle/projects/sc-nu
   ./setup.sh
   ```

3. Start Nushell:

   ```bash
   nu
   ```

`setup.sh` installs `env.nu` and `config.nu` in `~/.config/nushell`. On macOS, it also links `~/Library/Application Support/nushell` to that directory. This gives macOS and Linux the same configuration path. If the old macOS directory contains Nushell data, the script moves that data to the XDG directory. If a file conflicts, the script keeps a timestamped backup.

Run the read-only doctor command when you want to check the installation:

```bash
./doctor.sh
```

Run `./setup.sh` again to repair missing links or directories. The script does not delete existing files. Set `XDG_CONFIG_HOME` to an absolute directory before setup when you use a custom XDG location.

Run `./scripts/validate-cache.sh` to test integration cache generation and invalidation in an isolated home directory.

## Profiling and Benchmarking

Run this command to measure cold startup time:

```bash
nu -c 'timeit { nu -c "exit" }'
```

Expected time: **15 ms to 25 ms**.
