# Nushell Aliases (sc-nu)

# ------------------------------------------------------------------------------
# Core & File System
# ------------------------------------------------------------------------------
export alias less = less -FSRXc
export alias bat = bat --theme="Dracula" --italic-text=always --paging=always --color=always

# Listing & Navigation
# Native Nushell `ls` returns structured tables that support pipelines (| where, | sort-by, | get).
export alias ll = ls -l
export alias la = ls -a

# Eza for dedicated visual formatting and tree view
export alias ez = eza --icons --group-directories-first
export alias lt = eza --tree --icons
export alias lg = eza -l --git --git-repos --icons

# ------------------------------------------------------------------------------
# Development
# ------------------------------------------------------------------------------
# Python
export alias python = python3
export alias pip = python3 -m pip
export alias ipy = python3 -m IPython
export alias uv.exp = uv export --format requirements-txt --no-hashes --output-file requirements.txt --quiet
export alias brew.bundle = brew bundle dump --global --force

# ------------------------------------------------------------------------------
# System & Monitoring (macOS)
# ------------------------------------------------------------------------------
export alias top = top -R -F -s 5
export alias dns = scutil --dns
export alias ip.info = scutil --nwi

# Tmux
export alias tx = tmux-exec
export alias tn = tmux new-session -A -s Notes -c $"($env.HOME)/silentcastle/notes" "nvim scratch.md"

# Formatted timestamp
export def timestamp [] {
    date now | format date "%Y-%m-%dT%H:%M:%S%z"
}
