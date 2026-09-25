#!/usr/bin/env bash
set -euo pipefail

# sc-nu Setup & Symlink Script
# Links sc-nu into Nushell's configuration directories on macOS

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NU_MAC_DIR="$HOME/Library/Application Support/nushell"
NU_XDG_DIR="$HOME/.config/nushell"

echo "=== Setting up sc-nu for Nushell ==="

# Ensure directories exist
mkdir -p "$NU_MAC_DIR"
mkdir -p "$NU_XDG_DIR/local"

# Helper to safely create symlink
link_file() {
    local src="$1"
    local dst="$2"

    if [[ -e "$dst" || -L "$dst" ]]; then
        if [[ "$(readlink "$dst" 2>/dev/null || true)" == "$src" ]]; then
            echo "✔ Already linked: $dst"
            return 0
        fi
        echo "Backing up existing $dst to ${dst}.bak"
        mv "$dst" "${dst}.bak"
    fi

    ln -s "$src" "$dst"
    echo "✔ Linked: $dst -> $src"
}

# Link config.nu and env.nu to macOS Application Support directory
link_file "$SCRIPT_DIR/env.nu" "$NU_MAC_DIR/env.nu"
link_file "$SCRIPT_DIR/config.nu" "$NU_MAC_DIR/config.nu"

# Link local customizations directory
mkdir -p "$SCRIPT_DIR/local"
if [[ -d "$NU_XDG_DIR/local" && ! -L "$NU_XDG_DIR/local" ]]; then
    rm -rf "$NU_XDG_DIR/local"
fi
link_file "$SCRIPT_DIR/local" "$NU_XDG_DIR/local"

echo ""
echo "✔ Setup complete! You can now start Nushell by running:"
echo "    nu"
echo ""
