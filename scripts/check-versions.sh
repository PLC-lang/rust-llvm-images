#!/bin/bash
# Checks for updates to dependencies and outputs version information
# Used by the update-versions workflow

set -e

# Input: optional override versions from environment
# RUST_OVERRIDE, LLVM_OVERRIDE, GIT_OVERRIDE, SEVENZIP_OVERRIDE

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Get current versions from Dockerfiles
get_current_versions() {
    RUST_CURRENT=$(grep -oP 'RUST_VERSION=\K[0-9.]+' "$ROOT_DIR/linux/Dockerfile" | head -1)
    LLVM_CURRENT=$(grep -oP 'LLVM_VERSION=\K[0-9.]+' "$ROOT_DIR/windows/Dockerfile" | head -1)
    LLVM_MAJOR_CURRENT=$(grep -oP 'LLVM_VERSION=\K[0-9]+' "$ROOT_DIR/linux/Dockerfile" | head -1)
    GIT_CURRENT=$(grep -oP 'GIT_VERSION=\K[0-9.]+' "$ROOT_DIR/windows/Dockerfile" | head -1)
    SEVENZIP_CURRENT=$(grep -oP 'SEVENZIP_VERSION=\K[0-9]+' "$ROOT_DIR/windows/Dockerfile" | head -1)
}

# Get latest versions from upstream
get_latest_versions() {
    # Rust
    if [ -n "$RUST_OVERRIDE" ]; then
        RUST_LATEST="$RUST_OVERRIDE"
    else
        RUST_LATEST=$(curl -s https://static.rust-lang.org/dist/channel-rust-stable.toml | grep -oP 'cargo-\K[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    fi

    # LLVM from ghaith/llvm-package-windows
    if [ -n "$LLVM_OVERRIDE" ]; then
        LLVM_LATEST="$LLVM_OVERRIDE"
    else
        LLVM_LATEST=$(gh api repos/ghaith/llvm-package-windows/releases/latest --jq '.tag_name' | sed 's/^v//')
    fi
    LLVM_MAJOR_LATEST=$(echo "$LLVM_LATEST" | grep -oP '^\d+')

    # Git for Windows
    if [ -n "$GIT_OVERRIDE" ]; then
        GIT_LATEST="$GIT_OVERRIDE"
    else
        GIT_LATEST=$(gh api repos/git-for-windows/git/releases/latest --jq '.tag_name' | grep -oP '[0-9]+\.[0-9]+\.[0-9]+')
    fi

    # 7-Zip
    if [ -n "$SEVENZIP_OVERRIDE" ]; then
        SEVENZIP_LATEST="$SEVENZIP_OVERRIDE"
    else
        SEVENZIP_LATEST=$(curl -s https://www.7-zip.org/download.html | grep -oP '7z\K[0-9]{4}(?=-x64\.exe)' | head -1)
    fi
}

# Compare and determine what needs updating
check_updates() {
    HAS_UPDATE=false
    SUMMARY=""

    # Only Rust and LLVM trigger rebuilds
    if [ "$RUST_CURRENT" != "$RUST_LATEST" ]; then
        SUMMARY="${SUMMARY}- Rust: ${RUST_CURRENT} → ${RUST_LATEST}\n"
        HAS_UPDATE=true
    fi

    if [ "$LLVM_CURRENT" != "$LLVM_LATEST" ]; then
        SUMMARY="${SUMMARY}- LLVM: ${LLVM_CURRENT} → ${LLVM_LATEST}\n"
        HAS_UPDATE=true
    fi

    # Git and 7-Zip updated opportunistically
    if [ "$HAS_UPDATE" = true ]; then
        if [ "$GIT_CURRENT" != "$GIT_LATEST" ]; then
            SUMMARY="${SUMMARY}- Git: ${GIT_CURRENT} → ${GIT_LATEST}\n"
        fi
        if [ "$SEVENZIP_CURRENT" != "$SEVENZIP_LATEST" ]; then
            SUMMARY="${SUMMARY}- 7-Zip: ${SEVENZIP_CURRENT} → ${SEVENZIP_LATEST}\n"
        fi
    fi
}

# Output for GitHub Actions
output_github_actions() {
    local output_file="${GITHUB_OUTPUT:-/dev/stdout}"
    
    {
        echo "rust_current=$RUST_CURRENT"
        echo "rust_latest=$RUST_LATEST"
        echo "llvm_current=$LLVM_CURRENT"
        echo "llvm_latest=$LLVM_LATEST"
        echo "llvm_major=$LLVM_MAJOR_LATEST"
        echo "git_current=$GIT_CURRENT"
        echo "git_latest=$GIT_LATEST"
        echo "sevenzip_current=$SEVENZIP_CURRENT"
        echo "sevenzip_latest=$SEVENZIP_LATEST"
        echo "has_update=$HAS_UPDATE"
        echo "summary<<EOF"
        echo -e "$SUMMARY"
        echo "EOF"
    } >> "$output_file"
}

# Print human-readable summary
print_summary() {
    echo "Current versions:"
    echo "  Rust: $RUST_CURRENT"
    echo "  LLVM: $LLVM_CURRENT (major: $LLVM_MAJOR_CURRENT)"
    echo "  Git: $GIT_CURRENT"
    echo "  7-Zip: $SEVENZIP_CURRENT"
    echo ""
    echo "Latest versions:"
    echo "  Rust: $RUST_LATEST"
    echo "  LLVM: $LLVM_LATEST (major: $LLVM_MAJOR_LATEST)"
    echo "  Git: $GIT_LATEST"
    echo "  7-Zip: $SEVENZIP_LATEST"
    echo ""
    
    if [ "$HAS_UPDATE" = true ]; then
        echo "Updates available:"
        echo -e "$SUMMARY"
    else
        echo "All versions are up to date"
    fi
}

# Main
get_current_versions
get_latest_versions
check_updates
print_summary

if [ -n "$GITHUB_OUTPUT" ]; then
    output_github_actions
fi
