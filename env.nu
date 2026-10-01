# Nushell Environment Configuration (sc-nu)
# Evaluated before config.nu for both interactive and non-interactive shells.

# ------------------------------------------------------------------------------
# Cache & Workspace Directories
# ------------------------------------------------------------------------------
let cache_dir = $nu.cache-dir
if not ($cache_dir | path exists) {
    mkdir $cache_dir
}
$env.NU_CACHE_DIR = $cache_dir

# ------------------------------------------------------------------------------
# Local Directory & Placeholder Setup (Ensures parse-time safety for optional sources)
# ------------------------------------------------------------------------------
let local_dir = ($nu.default-config-dir | path join "local")
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
def cache_fingerprint [tool_version: string generation_command: string] {
    let nu_version = (version).version
    [
        "format=2"
        $"nu=($nu_version)"
        $"tool=($tool_version)"
        $"command=($generation_command)"
        $"bridges=($env.CARAPACE_BRIDGES)"
    ] | str join (char nl)
}

def cache_needs_update [target: string version_file: string fingerprint: string] {
    if not ($target | path exists) {
        return true
    }
    if ($target | open | str trim | is-empty) {
        return true
    }
    if not ($version_file | path exists) {
        return true
    }
    ($version_file | open | str trim) != $fingerprint
}

def write_cache_atomic [target: string content: string] {
    let temporary = $"($target).tmp.(random uuid)"
    $content | save -f $temporary
    mv -f $temporary $target
}

def ensure_cache_placeholder [target: string] {
    if not ($target | path exists) {
        write_cache_atomic $target ""
    }
}

def tool_version [tool: string] {
    if (which $tool | is-empty) {
        "unavailable"
    } else {
        ^$tool --version | lines | str join " " | str trim
    }
}

# Starship
let starship_target = ($cache_dir | path join "starship.nu")
let starship_version_file = ($cache_dir | path join "starship.version")
let starship_version = (tool_version "starship")
let starship_fingerprint = (cache_fingerprint $starship_version "starship init nu")
ensure_cache_placeholder $starship_target
if (which starship | is-not-empty) and (cache_needs_update $starship_target $starship_version_file $starship_fingerprint) {
    let generated = (starship init nu | str join (char nl))
    write_cache_atomic $starship_target $generated
    write_cache_atomic $starship_version_file $starship_fingerprint
} else if not ($starship_version_file | path exists) {
    write_cache_atomic $starship_version_file $starship_fingerprint
}

# Carapace
let carapace_target = ($cache_dir | path join "carapace.nu")
let carapace_version_file = ($cache_dir | path join "carapace.version")
let carapace_version = (tool_version "carapace")
let carapace_fingerprint = (cache_fingerprint $carapace_version "carapace _carapace nushell; adapter=place-v1")
ensure_cache_placeholder $carapace_target
if (which carapace | is-not-empty) and (cache_needs_update $carapace_target $carapace_version_file $carapace_fingerprint) {
    let generated = (carapace _carapace nushell | str join (char nl))
    let legacy_header = "let carapace_completer = {|spans|"
    let compatible_header = ("let carapace_completer = {|place|" + (char nl) + "  let spans = $place.command")
    let adapted = if ($generated | str contains $legacy_header) {
        $generated | str replace $legacy_header $compatible_header
    } else {
        $generated
    }
    write_cache_atomic $carapace_target $adapted
    write_cache_atomic $carapace_version_file $carapace_fingerprint
} else if not ($carapace_version_file | path exists) {
    write_cache_atomic $carapace_version_file $carapace_fingerprint
}

# Zoxide
let zoxide_target = ($cache_dir | path join "zoxide.nu")
let zoxide_version_file = ($cache_dir | path join "zoxide.version")
let zoxide_version = (tool_version "zoxide")
let zoxide_fingerprint = (cache_fingerprint $zoxide_version "zoxide init --no-cmd nushell")
ensure_cache_placeholder $zoxide_target
if (which zoxide | is-not-empty) and (cache_needs_update $zoxide_target $zoxide_version_file $zoxide_fingerprint) {
    # Keep Nu's native `cd` completion. Its special completion handling can
    # otherwise mix command candidates into the fuzzy directory menu.
    let generated = $"((zoxide init --no-cmd nushell))\nexport alias z = __zoxide_z\nexport alias zi = __zoxide_zi\n"
    write_cache_atomic $zoxide_target $generated
    write_cache_atomic $zoxide_version_file $zoxide_fingerprint
} else if not ($zoxide_version_file | path exists) {
    write_cache_atomic $zoxide_version_file $zoxide_fingerprint
}

# ------------------------------------------------------------------------------
# Local Pre Customizations
# ------------------------------------------------------------------------------
source ($nu.default-config-dir | path join "local/pre.nu")
