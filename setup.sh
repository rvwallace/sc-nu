#!/usr/bin/env bash
set -euo pipefail

# Install sc-nu in Nushell's XDG configuration directory.
# On macOS, keep Application Support as a compatibility symlink.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XDG_ROOT="${XDG_CONFIG_HOME:-$HOME/.config}"
if [[ "$XDG_ROOT" != /* ]]; then
    echo "XDG_CONFIG_HOME must be an absolute path: $XDG_ROOT" >&2
    exit 1
fi

NU_XDG_DIR="$XDG_ROOT/nushell"
NU_MAC_DIR="$HOME/Library/Application Support/nushell"
BACKUP_SUFFIX="$(date +%Y%m%d%H%M%S)"

echo "=== Setting up sc-nu for Nushell ==="
mkdir -p "$NU_XDG_DIR"

backup_path() {
    local path="$1"
    local backup="${path}.bak_${BACKUP_SUFFIX}"
    local counter=1

    while [[ -e "$backup" || -L "$backup" ]]; do
        backup="${path}.bak_${BACKUP_SUFFIX}_${counter}"
        counter=$((counter + 1))
    done

    mv "$path" "$backup"
    echo "Backed up $path to $backup"
}

link_file() {
    local src="$1"
    local dst="$2"

    if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
        echo "✔ Already linked: $dst"
        return 0
    fi

    if [[ -e "$dst" || -L "$dst" ]]; then
        backup_path "$dst"
    fi

    ln -s "$src" "$dst"
    echo "✔ Linked: $dst -> $src"
}

migrate_macos_directory() {
    if [[ -L "$NU_MAC_DIR" && "$(readlink "$NU_MAC_DIR")" == "$NU_XDG_DIR" ]]; then
        echo "✔ macOS Application Support path already links to $NU_XDG_DIR"
        return 0
    fi

    if [[ -d "$NU_MAC_DIR" && ! -L "$NU_MAC_DIR" ]]; then
        echo "Migrating existing macOS Nushell data to $NU_XDG_DIR"
        shopt -s dotglob nullglob
        local entry name destination
        for entry in "$NU_MAC_DIR"/*; do
            name="${entry##*/}"
            destination="$NU_XDG_DIR/$name"
            if [[ -e "$destination" || -L "$destination" ]]; then
                backup_path "$destination"
            fi
            mv "$entry" "$destination"
        done
        shopt -u dotglob nullglob
        rmdir "$NU_MAC_DIR"
    elif [[ -e "$NU_MAC_DIR" || -L "$NU_MAC_DIR" ]]; then
        backup_path "$NU_MAC_DIR"
    fi

    mkdir -p "$(dirname "$NU_MAC_DIR")"
    ln -s "$NU_XDG_DIR" "$NU_MAC_DIR"
    echo "✔ Linked: $NU_MAC_DIR -> $NU_XDG_DIR"
}

ensure_local_directory() {
    local local_dir="$NU_XDG_DIR/local"

    if [[ -L "$local_dir" ]]; then
        local old_local_backup="${local_dir}.bak_${BACKUP_SUFFIX}"
        local counter=1
        while [[ -e "$old_local_backup" || -L "$old_local_backup" ]]; do
            old_local_backup="${local_dir}.bak_${BACKUP_SUFFIX}_${counter}"
            counter=$((counter + 1))
        done
        mv "$local_dir" "$old_local_backup"
        mkdir -p "$local_dir"
        if [[ -d "$old_local_backup" ]]; then
            cp -a "$old_local_backup"/. "$local_dir"/
        else
            echo "Warning: $old_local_backup is not a directory. Its backup was kept."
        fi
        echo "Moved local customizations into $local_dir"
    elif [[ -e "$local_dir" && ! -d "$local_dir" ]]; then
        backup_path "$local_dir"
        mkdir -p "$local_dir"
    else
        mkdir -p "$local_dir"
    fi

    touch "$local_dir/pre.nu" "$local_dir/post.nu"
}

if [[ "$(uname -s)" == "Darwin" ]]; then
    migrate_macos_directory
fi

link_file "$SCRIPT_DIR/env.nu" "$NU_XDG_DIR/env.nu"
link_file "$SCRIPT_DIR/config.nu" "$NU_XDG_DIR/config.nu"
ensure_local_directory

echo
echo "✔ Setup complete"
echo "  Nushell config: $NU_XDG_DIR"
if [[ "$(uname -s)" == "Darwin" ]]; then
    echo "  macOS compatibility path: $NU_MAC_DIR -> $NU_XDG_DIR"
fi
echo "  Run ./doctor.sh to check the installation."
