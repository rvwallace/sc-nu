# Nushell Environment Configuration (sc-nu)
# Evaluated before config.nu for both interactive and non-interactive shells.

# ------------------------------------------------------------------------------
# Cache & Workspace Directories
# ------------------------------------------------------------------------------
let cache_dir = ($env.XDG_CACHE_HOME? | default ($env.HOME | path join ".cache") | path join "nushell")
if not ($cache_dir | path exists) {
    mkdir $cache_dir
}
$env.NU_CACHE_DIR = $cache_dir

# ------------------------------------------------------------------------------
# Local Directory & Placeholder Setup (Ensures parse-time safety for optional sources)
# ------------------------------------------------------------------------------
let local_dir = ($env.HOME | path join ".config/nushell/local")
let local_pre = ($local_dir | path join "pre.nu")
let local_post = ($local_dir | path join "post.nu")

if not ($local_dir | path exists) {
    mkdir $local_dir
}
if not ($local_pre | path exists) {
    "" | save -f $local_pre
}
if not ($local_post | path exists) {
    "" | save -f $local_post
}

# ------------------------------------------------------------------------------
# Homebrew Detection
# ------------------------------------------------------------------------------
let brew_prefix = if ("/opt/homebrew/bin/brew" | path exists) {
    "/opt/homebrew"
} else if ("/usr/local/bin/brew" | path exists) {
    "/usr/local"
} else if ("/home/linuxbrew/.linuxbrew/bin/brew" | path exists) {
    "/home/linuxbrew/.linuxbrew"
} else {
    ""
}

if ($brew_prefix | is-not-empty) {
    $env.HOMEBREW_PREFIX = $brew_prefix
    $env.HOMEBREW_CELLAR = ($brew_prefix | path join "Cellar")
    $env.HOMEBREW_REPOSITORY = $brew_prefix
}

# ------------------------------------------------------------------------------
# PATH Construction (ordered with user paths taking highest priority)
# ------------------------------------------------------------------------------
let user_paths = [
    $"($env.HOME)/.cargo/bin"
    $"($env.HOME)/.local/bin"
    $"($env.HOME)/go/bin"
    $"($env.HOME)/.npm-global/bin"
    $"($env.HOME)/.opencode/bin"
    "/opt/homebrew/opt/ruby/bin"
    (if ($brew_prefix | is-not-empty) { $"($brew_prefix)/bin" } else { "" })
    (if ($brew_prefix | is-not-empty) { $"($brew_prefix)/sbin" } else { "" })
    $"($env.HOME)/.antigravity/antigravity/bin"
    $"($env.HOME)/.bun/bin"
    "/Applications/Obsidian.app/Contents/MacOS"
    $"($env.HOME)/silentcastle/projects/toolbox/bin"
]

$env.PATH = (
    $env.PATH
    | split row (char esep)
    | prepend ($user_paths | where { ($in | is-not-empty) and ($in | path exists) })
    | uniq
)

# ------------------------------------------------------------------------------
# Environment Variables
# ------------------------------------------------------------------------------
$env.TERM = "xterm-256color"
$env.LANG = "en_US.UTF-8"
$env.LC_ALL = "en_US.UTF-8"
$env.PAGER = "less"

# Dynamic Editor Selection
$env.EDITOR = (
    [nvim hx vim vi nano]
    | where { (which $in | is-not-empty) }
    | get 0?
    | default "nano"
)

# Tool settings
$env.STARSHIP_LOG = "error"
$env.CARAPACE_BRIDGES = "gen,zsh,fish,bash,inshellisense"

# ------------------------------------------------------------------------------
# Integration Script Pre-generation (Cached)
# ------------------------------------------------------------------------------
# Starship
if (which starship | is-not-empty) {
    let target = ($cache_dir | path join "starship.nu")
    if not ($target | path exists) {
        starship init nu | save -f $target
    }
}

# Carapace
if (which carapace | is-not-empty) {
    let target = ($cache_dir | path join "carapace.nu")
    if not ($target | path exists) {
        carapace _carapace nushell | save -f $target
    }
}

# Zoxide
if (which zoxide | is-not-empty) {
    let target = ($cache_dir | path join "zoxide.nu")
    if not ($target | path exists) {
        zoxide init --cmd cd nushell | save -f $target
    }
}

# ------------------------------------------------------------------------------
# Local Pre Customizations
# ------------------------------------------------------------------------------
source ~/.config/nushell/local/pre.nu
