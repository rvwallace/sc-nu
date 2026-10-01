# Nushell Configuration (sc-nu)
# Evaluated for interactive sessions.

# Use tfswitch's configured binary path when available. In a PWD hook,
# tfswitch's automatic path detection can fall back to ~/bin because the hook
# is non-interactive, so use the Terraform executable currently on PATH as the
# fallback target.
let tfswitch_config = ($env.HOME | path join ".tfswitch.toml")
let configured_tfswitch_bin = if ($tfswitch_config | path exists) {
    open $tfswitch_config | get -o bin
} else {
    null
}
let resolved_tfswitch_bin = if ($configured_tfswitch_bin | is-not-empty) {
    $configured_tfswitch_bin
    | str replace --regex '^\$HOME' $env.HOME
    | str replace --regex '^~' $env.HOME
    | path expand --no-symlink
} else {
    which terraform
    | where type == external
    | get path
    | first
    | default ($env.HOME | path join ".local/bin/terraform")
}
$env.TFSWITCH_BIN = $resolved_tfswitch_bin

# ------------------------------------------------------------------------------
# Core Shell Settings
# ------------------------------------------------------------------------------
$env.config = {
    show_banner: false
    edit_mode: "emacs"
    cursor_shape: {
        emacs: "line"
        vi_insert: "line"
        vi_normal: "block"
    }
    history: {
        max_size: 100000
        sync_on_enter: true
        file_format: "sqlite"
        isolation: false
    }
    completions: {
        case_sensitive: false
        quick: true
        partial: true
        algorithm: "fuzzy"
    }
    hooks: {
        env_change: {
            PWD: [
                # Auto-run tfswitch if entering a terraform project
                { |before, after|
                    if ([".terraform-version", ".tfswitchrc", "versions.tf"] | any { |f| $f | path exists }) {
                        if (which tfswitch | is-not-empty) {
                            try {
                                if ($env.TFSWITCH_BIN | is-empty) {
                                    do -c { ^tfswitch }
                                } else {
                                    do -c { ^tfswitch --bin $env.TFSWITCH_BIN }
                                }
                            } catch {|err|
                                print $err.rendered
                            }
                        }
                    }
                }
            ]
        }
    }
    buffer_editor: ($env.EDITOR? | default "nvim")
    # Disable OSC 8 hyperlinks to prevent upstream ansi-to-tui / tmux-snaglord
    # parser bug from swallowing table columns in captured pane output
    ls: {
        use_ls_colors: true
        clickable_links: false
    }
    shell_integration: {
        osc8: false
    }
}

# ------------------------------------------------------------------------------
# App Integrations (Carapace, Starship, Zoxide)
# ------------------------------------------------------------------------------
const cache_dir = $nu.cache-dir

# Carapace completion bridge
source ($cache_dir | path join "carapace.nu")

# Zoxide smart directory jumper (`z` and `zi`; native `cd` keeps path completion)
source ($cache_dir | path join "zoxide.nu")

# Starship prompt
source ($cache_dir | path join "starship.nu")

# ------------------------------------------------------------------------------
# Internal Modules & Helpers
# ------------------------------------------------------------------------------
const sc_nu_dir = ($nu.config-path | path dirname)
source ($sc_nu_dir | path join "modules/aliases.nu")
source ($sc_nu_dir | path join "modules/commands.nu")

# ------------------------------------------------------------------------------
# User Local Post Customizations
# ------------------------------------------------------------------------------
const local_post_path = ($nu.default-config-dir | path join "local/post.nu")
const local_post = if ($local_post_path | path exists) { $local_post_path } else { null }
source $local_post
