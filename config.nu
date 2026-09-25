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
    keybindings: [
        # Alt-E: Open command line in $EDITOR (Note: Ctrl-O is also built-in natively)
        {
            name: open_editor_alt
            modifier: alt
            keycode: char_e
            mode: [emacs, vi_insert]
            event: { send: OpenEditor }
        }
        # Ctrl-G and Alt-G: Quick Git status
        {
            name: quick_git_status_ctrl
            modifier: control
            keycode: char_g
            mode: [emacs, vi_insert]
            event: {
                send: executehostcommand
                cmd: "if (git rev-parse --is-inside-work-tree err> /dev/null | str trim) == 'true' { git status -sb } else { print 'Not a git repository' }"
            }
        }
        {
            name: quick_git_status_alt
            modifier: alt
            keycode: char_g
            mode: [emacs, vi_insert]
            event: {
                send: executehostcommand
                cmd: "if (git rev-parse --is-inside-work-tree err> /dev/null | str trim) == 'true' { git status -sb } else { print 'Not a git repository' }"
            }
        }
        # Alt-L: Quick ls preview
        {
            name: quick_ls_alt
            modifier: alt
            keycode: char_l
            mode: [emacs, vi_insert]
            event: {
                send: executehostcommand
                cmd: "ls"
            }
        }
    ]
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
use /Users/robert.wallace/silentcastle/projects/sc-nu/modules/aliases.nu *
use /Users/robert.wallace/silentcastle/projects/sc-nu/modules/commands.nu *

# ------------------------------------------------------------------------------
# Toolbox Shell Modules
# ------------------------------------------------------------------------------
use /Users/robert.wallace/silentcastle/projects/toolbox/shell/init.nu *

# ------------------------------------------------------------------------------
# User Local Post Customizations
# ------------------------------------------------------------------------------
source ~/.config/nushell/local/post.nu
