# Nushell Configuration (sc-nu)
# Evaluated for interactive sessions.

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
                            ^tfswitch
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
# Carapace completion bridge
source ~/.cache/nushell/carapace.nu

# Zoxide smart directory jumper (aliases cd, cdi, z, zi)
source ~/.cache/nushell/zoxide.nu

# Starship prompt
use ~/.cache/nushell/starship.nu

# ------------------------------------------------------------------------------
# Internal Modules & Helpers
# ------------------------------------------------------------------------------
const sc_nu_dir = ($nu.config-path | path dirname)
source ($sc_nu_dir | path join "modules/aliases.nu")
source ($sc_nu_dir | path join "modules/commands.nu")

# ------------------------------------------------------------------------------
# User Local Post Customizations
# ------------------------------------------------------------------------------
source ($nu.default-config-dir | path join "local/post.nu")
