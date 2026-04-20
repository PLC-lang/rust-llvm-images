#!/usr/bin/env bash
# Runs the update workflow shell scripts in a clean Ubuntu container.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
IMAGE="${TEST_IMAGE:-ubuntu:24.04}"

if ! command -v docker >/dev/null 2>&1; then
    echo "docker is required" >&2
    exit 1
fi

docker run --rm -v "$ROOT_DIR":/src:ro "$IMAGE" bash -lc '
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update >/dev/null
apt-get install -y --no-install-recommends ca-certificates curl grep sed coreutils findutils >/dev/null

format_tag() {
  local llvm="$1" rust="$2"
  local rust_major rust_minor rust_patch rust_tag
  IFS="." read -r rust_major rust_minor rust_patch <<< "$rust"
  rust_tag="${rust_major}.${rust_minor}"
  if [ -n "${rust_patch:-}" ] && [ "$rust_patch" != "0" ]; then
    rust_tag="${rust_tag}-${rust_patch}"
  fi
  printf "v%s-%s\n" "$llvm" "$rust_tag"
}

copy_repo() {
  rm -rf /tmp/repo
  mkdir -p /tmp/repo
  cp -a /src/. /tmp/repo/
  cd /tmp/repo
}

echo "== syntax =="
cd /src
bash -n scripts/check-versions.sh
bash -n scripts/update-versions.sh
bash -n scripts/validate-urls.sh

echo "== current release tag from repo =="
RUST=$(grep -oP "RUST_VERSION=\\K[0-9.]+" linux/Dockerfile | head -1)
LLVM=$(grep -oP "LLVM_VERSION=\\K[0-9]+" linux/Dockerfile | head -1)
TAG=$(format_tag "$LLVM" "$RUST")
printf "rust=%s llvm=%s tag=%s\n" "$RUST" "$LLVM" "$TAG"

echo "== tag edge cases =="
[ "$(format_tag 21 1.95.0)" = "v21-1.95" ]
[ "$(format_tag 21 1.95.1)" = "v21-1.95-1" ]
[ "$(format_tag 21 1.96.0)" = "v21-1.96" ]
printf "tag tests passed\n"

echo "== check-versions no update =="
copy_repo
out=$(mktemp)
RUST_OVERRIDE=1.95.0 LLVM_OVERRIDE=21.1.7 GIT_OVERRIDE=2.53.0 SEVENZIP_OVERRIDE=2600 GITHUB_OUTPUT="$out" ./scripts/check-versions.sh >/tmp/check-no-update.txt
grep -Fx "has_update=false" "$out"

echo "== check-versions git/7zip only do not trigger =="
copy_repo
out=$(mktemp)
RUST_OVERRIDE=1.95.0 LLVM_OVERRIDE=21.1.7 GIT_OVERRIDE=2.54.0 SEVENZIP_OVERRIDE=2700 GITHUB_OUTPUT="$out" ./scripts/check-versions.sh >/tmp/check-tools-only.txt
grep -Fx "has_update=false" "$out"
! grep -Fq -- "- Git:" "$out"
! grep -Fq -- "- 7-Zip:" "$out"

echo "== check-versions update available =="
copy_repo
out=$(mktemp)
RUST_OVERRIDE=1.95.1 LLVM_OVERRIDE=21.1.8 GIT_OVERRIDE=2.54.0 SEVENZIP_OVERRIDE=2700 GITHUB_OUTPUT="$out" ./scripts/check-versions.sh >/tmp/check-update.txt
grep -Fx "has_update=true" "$out"
grep -F -- "- Rust: 1.95.0 → 1.95.1" "$out"
grep -F -- "- LLVM: 21.1.7 → 21.1.8" "$out"
grep -F -- "- Git: 2.53.0 → 2.54.0" "$out"
grep -F -- "- 7-Zip: 2600 → 2700" "$out"

echo "== update-versions applies patch update =="
copy_repo
RUST_CURRENT=1.95.0 \
RUST_LATEST=1.95.1 \
LLVM_CURRENT=21.1.7 \
LLVM_LATEST=21.1.8 \
LLVM_MAJOR=21 \
GIT_CURRENT=2.53.0 \
GIT_LATEST=2.54.0 \
SEVENZIP_CURRENT=2600 \
SEVENZIP_LATEST=2700 \
./scripts/update-versions.sh >/tmp/update-versions-patch.txt
grep -F "ARG RUST_VERSION=1.95.1" linux/Dockerfile
grep -F "ARG RUST_VERSION=1.95.1" windows/Dockerfile
grep -F "ARG LLVM_VERSION=21" linux/Dockerfile
grep -F "ARG LLVM_VERSION=21.1.8" windows/Dockerfile
grep -F "ARG GIT_VERSION=2.54.0" windows/Dockerfile
grep -F "ARG SEVENZIP_VERSION=2700" windows/Dockerfile

echo "== update-versions applies llvm major update =="
copy_repo
RUST_CURRENT=1.95.0 \
RUST_LATEST=1.95.0 \
LLVM_CURRENT=21.1.7 \
LLVM_LATEST=22.0.0 \
LLVM_MAJOR=22 \
GIT_CURRENT=2.53.0 \
GIT_LATEST=2.53.0 \
SEVENZIP_CURRENT=2600 \
SEVENZIP_LATEST=2600 \
./scripts/update-versions.sh >/tmp/update-versions-major.txt
grep -F "ARG LLVM_VERSION=22" linux/Dockerfile
grep -F "ARG LLVM_VERSION=22.0.0" windows/Dockerfile

echo "== validate-urls =="
copy_repo
./scripts/validate-urls.sh | tee /tmp/validate-urls.txt >/dev/null
grep -F "https://aka.ms/vs/17/release/channel" /tmp/validate-urls.txt
grep -F "https://apt.llvm.org/llvm.sh" /tmp/validate-urls.txt
grep -F "https://sh.rustup.rs" /tmp/validate-urls.txt
grep -F "All URLs validated successfully" /tmp/validate-urls.txt

echo "== clean-container workflow script tests passed =="
'