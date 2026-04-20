#!/bin/bash
# Updates Dockerfiles with new versions
# Used by the update-versions workflow

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Required environment variables
: "${RUST_CURRENT:?}"
: "${RUST_LATEST:?}"
: "${LLVM_CURRENT:?}"
: "${LLVM_LATEST:?}"
: "${LLVM_MAJOR:?}"
: "${GIT_CURRENT:?}"
: "${GIT_LATEST:?}"
: "${SEVENZIP_CURRENT:?}"
: "${SEVENZIP_LATEST:?}"

# Update Rust in both Dockerfiles
if [ "$RUST_CURRENT" != "$RUST_LATEST" ]; then
    sed -i "s/RUST_VERSION=$RUST_CURRENT/RUST_VERSION=$RUST_LATEST/" \
        "$ROOT_DIR/linux/Dockerfile" "$ROOT_DIR/windows/Dockerfile"
    echo "Updated Rust: $RUST_CURRENT → $RUST_LATEST"
fi

# Update LLVM in windows/Dockerfile (full version)
if [ "$LLVM_CURRENT" != "$LLVM_LATEST" ]; then
    sed -i "s/LLVM_VERSION=$LLVM_CURRENT/LLVM_VERSION=$LLVM_LATEST/" "$ROOT_DIR/windows/Dockerfile"
    echo "Updated Windows LLVM: $LLVM_CURRENT → $LLVM_LATEST"
    
    # Update major version in linux/Dockerfile if changed
    OLD_MAJOR=$(echo "$LLVM_CURRENT" | grep -oP '^\d+')
    if [ "$OLD_MAJOR" != "$LLVM_MAJOR" ]; then
        sed -i "s/LLVM_VERSION=$OLD_MAJOR/LLVM_VERSION=$LLVM_MAJOR/" "$ROOT_DIR/linux/Dockerfile"
        echo "Updated Linux LLVM major: $OLD_MAJOR → $LLVM_MAJOR"
    fi
fi

# Update Git in windows/Dockerfile
if [ "$GIT_CURRENT" != "$GIT_LATEST" ]; then
    sed -i "s/GIT_VERSION=$GIT_CURRENT/GIT_VERSION=$GIT_LATEST/" "$ROOT_DIR/windows/Dockerfile"
    echo "Updated Git: $GIT_CURRENT → $GIT_LATEST"
fi

# Update 7-Zip in windows/Dockerfile
if [ "$SEVENZIP_CURRENT" != "$SEVENZIP_LATEST" ]; then
    sed -i "s/SEVENZIP_VERSION=$SEVENZIP_CURRENT/SEVENZIP_VERSION=$SEVENZIP_LATEST/" "$ROOT_DIR/windows/Dockerfile"
    echo "Updated 7-Zip: $SEVENZIP_CURRENT → $SEVENZIP_LATEST"
fi

echo ""
echo "Updated Dockerfiles:"
grep -E '(RUST_VERSION|LLVM_VERSION|GIT_VERSION|SEVENZIP_VERSION)=' \
    "$ROOT_DIR/linux/Dockerfile" "$ROOT_DIR/windows/Dockerfile"
