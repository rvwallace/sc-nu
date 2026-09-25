# sc-nu: Performance-Optimized Nushell Configuration

`sc-nu` is a modular, structured, performance-first Nushell configuration system designed to run alongside `sc-zsh`.

- **Cold Startup Time**: **~16ms** (compared to ~170ms in tuned Zsh, a >90% improvement).
- **Architecture**: Modular separation with native typed pipelines, SQLite history, and seamless tool integrations.
- **Toolbox Integration**: Native Nushell companion modules for AWS (`aws.env`), Kubernetes (`k.env`), Chef (`chef.env`), Git (`git.cdroot`), Tmux (`tp`), and Yazi (`y`).
- **Completions & Integrations**: Powered by Carapace multi-shell bridge, Starship prompt, and Zoxide directory jumper.

---

## Architecture & Directory Structure

```
~/silentcastle/projects/sc-nu/
├── env.nu                 # Environment variables, PATH deduplication, tool caching
├── config.nu              # Core options, keybindings, hooks, completion bridge
├── setup.sh               # Symlink installer for macOS & XDG
├── modules/
│   ├── aliases.nu         # General aliases (eza, bat, python, brew, tmux)
└── .gitignore             # Ignores local private files and history databases
```

### Local Customizations (Untracked)
- `~/.config/nushell/local/pre.nu` — Private environment variables, tokens, API keys (evaluated early in `env.nu`).
- `~/.config/nushell/local/post.nu` — Machine-specific commands or overrides (evaluated late in `config.nu`).

---

## Key Features

### 1. Toolbox Companion Modules (`projects/toolbox`)
`sc-nu` imports native Nushell companion modules located in `~/silentcastle/projects/toolbox/shell/init.nu`:
- **`aws.env`**: Interactive AWS profile/region switcher delegating to `aws-env` and exporting environment variables into the interactive shell with `def --env`.
- **`k.env`**: Kubernetes environment switcher (`select` from `~/.kube` with `fzf` + `bat` preview, `context`, `ns`, `clear`).
- **`chef.env`**: Chef environment switcher (`set` with `fzf` + `bat` preview, `clear`, `show`, `list`).
- **`git.cdroot`**: Jump directly to git repository root.
- **`tp`**: Run commands inside a tmux display popup window.
- **`y`**: Yazi wrapper that navigates to the directory chosen on exit.
- **`terraform`**: Auto-runs `tfswitch` on directory change via Nushell's `env_change.PWD` hook.

### 2. App Integrations
All major integrations are pre-generated into `~/.cache/nushell/` on startup:
- **Starship**: Fast, rich prompt rendered natively.
- **Carapace**: Primary completion bridge covering Git, Docker, Kubectl, AWS, GitHub CLI, and more with full tabular descriptions.
- **Zoxide**: Smart directory jumper aliasing `cd`.

### 3. Keybindings (Reedline)
- `Ctrl-X Ctrl-E`: Open and edit current command line in `$EDITOR` (`nvim`).
- `Ctrl-X g`: Quick Git status preview (`git status -sb`).
- `Ctrl-X l`: Quick directory listing (`ls`).
- `Up` / `Down`: History substring search.

---

## Installation & Setup

1. Install Nushell (if not already installed):
   ```bash
   brew install nushell
   ```

2. Link configuration to macOS Application Support and XDG directories:
   ```bash
   cd ~/silentcastle/projects/sc-nu
   ./setup.sh
   ```

3. Launch Nushell:
   ```bash
   nu
   ```

---

## Profiling & Benchmarking

To test cold startup time:
```bash
nu -c 'timeit { nu -c "exit" }'
```
*Expected: ~15ms - 25ms.*
