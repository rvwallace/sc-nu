#!/usr/bin/env bash
set -euo pipefail

# Check the sc-nu installation without changing user files.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XDG_ROOT="${XDG_CONFIG_HOME:-$HOME/.config}"
if [[ "$XDG_ROOT" != /* ]]; then
    echo "FAIL: XDG_CONFIG_HOME must be an absolute path: $XDG_ROOT" >&2
    exit 1
fi

NU_XDG_DIR="$XDG_ROOT/nushell"
NU_MAC_DIR="$HOME/Library/Application Support/nushell"
failures=0
warnings=0

pass() { echo "✔ $1"; }
fail() { echo "✘ $1"; failures=$((failures + 1)); }
warn() { echo "⚠ $1"; warnings=$((warnings + 1)); }

canonical_path() {
    (cd "$1" && pwd -P)
}

check_link() {
    local src="$1"
    local dst="$2"
    if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
        pass "$dst -> $src"
    else
        fail "$dst does not link to $src"
    fi
}

if [[ -d "$NU_XDG_DIR" && ! -L "$NU_XDG_DIR" ]]; then
    pass "XDG Nushell directory exists: $NU_XDG_DIR"
else
    fail "XDG Nushell directory is not a real directory: $NU_XDG_DIR"
fi

check_link "$SCRIPT_DIR/env.nu" "$NU_XDG_DIR/env.nu"
check_link "$SCRIPT_DIR/config.nu" "$NU_XDG_DIR/config.nu"

if [[ -d "$NU_XDG_DIR/local" && ! -L "$NU_XDG_DIR/local" ]]; then
    pass "Local customization directory is local to XDG: $NU_XDG_DIR/local"
else
    fail "Local customization directory is missing or still a symlink"
fi

for local_file in pre.nu post.nu; do
    if [[ -f "$NU_XDG_DIR/local/$local_file" ]]; then
        pass "Local startup file exists: $NU_XDG_DIR/local/$local_file"
    else
        fail "Local startup file is missing: $NU_XDG_DIR/local/$local_file"
    fi
done

if [[ "$(uname -s)" == "Darwin" ]]; then
    check_link "$NU_XDG_DIR" "$NU_MAC_DIR"
fi

if command -v nu >/dev/null 2>&1; then
    nu_dir="$(nu --no-config-file --commands 'print $nu.default-config-dir' 2>/dev/null)"
    expected_nu_dir="$(canonical_path "$NU_XDG_DIR")"
    actual_nu_dir="$(canonical_path "$nu_dir" 2>/dev/null || true)"
    if [[ "$actual_nu_dir" == "$expected_nu_dir" ]]; then
        pass "Nushell resolves its config directory to $NU_XDG_DIR"
    else
        fail "Nushell resolves its config directory to ${nu_dir:-<no output>}"
    fi
else
    fail "Nushell executable is not available"
fi

if command -v tfswitch >/dev/null 2>&1; then
    TFSWITCH_CONFIG="$HOME/.tfswitch.toml"
    if [[ ! -f "$TFSWITCH_CONFIG" ]]; then
        warn "tfswitch is installed but its config is missing: $TFSWITCH_CONFIG"
    elif rg -q '^[[:space:]]*bin[[:space:]]*=' "$TFSWITCH_CONFIG"; then
        pass "tfswitch config defines a binary path: $TFSWITCH_CONFIG"
    else
        warn "tfswitch config does not define bin: $TFSWITCH_CONFIG"
    fi
else
    pass "tfswitch is not installed; skipped tfswitch config check"
fi

if (( failures > 0 )); then
    echo "Doctor found $failures problem(s). Run ./setup.sh to repair the installation."
    exit 1
fi

if (( warnings > 0 )); then
    echo "Doctor found no blocking problems and $warnings warning(s)."
else
    echo "Doctor found no problems."
fi
