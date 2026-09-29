#!/usr/bin/env bash
set -euo pipefail

# Validate first generation, reuse, invalidation, and Carapace adaptation.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_HOME="$(mktemp -d /tmp/sc-nu-cache-validation.XXXXXX)"
trap 'rm -rf "$TEST_HOME"' EXIT

CONFIG_HOME="$TEST_HOME/config"
CACHE_HOME="$TEST_HOME/cache"

mtime() {
    stat -c '%Y' "$1" 2>/dev/null || stat -f '%m' "$1"
}

run_nu() {
    HOME="$TEST_HOME" \
    XDG_CONFIG_HOME="$CONFIG_HOME" \
    XDG_CACHE_HOME="$CACHE_HOME" \
    nu --login --commands 'exit'
}

assert_file() {
    if [[ ! -s "$1" ]]; then
        echo "Missing or empty file: $1" >&2
        exit 1
    fi
}

assert_placeholder_or_cache() {
    local tool="$1"
    local target="$2"
    if command -v "$tool" >/dev/null 2>&1; then
        assert_file "$target"
    elif [[ ! -f "$target" ]]; then
        echo "Missing placeholder: $target" >&2
        exit 1
    fi
}

HOME="$TEST_HOME" XDG_CONFIG_HOME="$CONFIG_HOME" "$REPO_DIR/setup.sh" >/dev/null
run_nu

for integration in carapace starship zoxide; do
    assert_placeholder_or_cache "$integration" "$CACHE_HOME/nushell/$integration.nu"
    assert_file "$CACHE_HOME/nushell/$integration.version"
done

carapace_cache="$CACHE_HOME/nushell/carapace.nu"
carapace_version="$CACHE_HOME/nushell/carapace.version"
carapace_mtime="$(mtime "$carapace_cache")"

run_nu
if [[ "$(mtime "$carapace_cache")" != "$carapace_mtime" ]]; then
    echo "Cache changed when its fingerprint matched" >&2
    exit 1
fi

rm "$carapace_version"
run_nu
assert_file "$carapace_version"

sleep 1
printf '%s\n' 'malformed sidecar' > "$carapace_version"
run_nu
if grep -Fq 'malformed sidecar' "$carapace_version"; then
    echo "Malformed sidecar was not replaced" >&2
    exit 1
fi

sleep 1
rm "$carapace_cache"
run_nu
assert_file "$carapace_cache"

if command -v carapace >/dev/null 2>&1; then
    if grep -Fq 'let carapace_completer = {|spans|' "$carapace_cache"; then
        echo "Carapace cache still uses the deprecated spans input" >&2
        exit 1
    fi
    grep -Fq 'let carapace_completer = {|place|' "$carapace_cache"

    completion_output="$(
        HOME="$TEST_HOME" \
        XDG_CONFIG_HOME="$CONFIG_HOME" \
        XDG_CACHE_HOME="$CACHE_HOME" \
        nu --login --commands "'git ' | commandline complete; exit" 2>&1
    )"
    if printf '%s\n' "$completion_output" | grep -Eiq 'deprecated|positional completer input'; then
        echo "Carapace completion emitted a deprecated completer warning" >&2
        exit 1
    fi
fi

echo "Cache validation passed."
