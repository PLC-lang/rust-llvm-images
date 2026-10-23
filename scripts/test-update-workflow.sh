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

echo "== current dependency versions from repo =="
RUST_CUR=$(grep -oP "RUST_VERSION=\\K[0-9.]+" linux/Dockerfile | head -1)
LLVM_CUR=$(grep -oP "LLVM_VERSION=\\K[0-9.]+" windows/Dockerfile | head -1)
LLVM_MAJOR_CUR=${LLVM_CUR%%.*}
GIT_CUR=$(grep -oP "GIT_VERSION=\\K[0-9.]+" windows/Dockerfile | head -1)
SEVENZIP_CUR=$(grep -oP "SEVENZIP_VERSION=\\K[0-9]+" windows/Dockerfile | head -1)
UV_CUR=$(grep -oP "astral-sh/uv:\\K[0-9.]+" linux/Dockerfile | head -1)
printf "rust=%s llvm=%s git=%s 7zip=%s uv=%s\n" "$RUST_CUR" "$LLVM_CUR" "$GIT_CUR" "$SEVENZIP_CUR" "$UV_CUR"

# Synthetic "newer" versions derived from the current ones, so the tests
# do not go stale whenever the Dockerfiles are bumped
bump_patch() {
  local major minor patch
  IFS="." read -r major minor patch <<< "$1"
  printf "%s.%s.%s\n" "$major" "$minor" "$((patch + 1))"
}
RUST_NEW=$(bump_patch "$RUST_CUR")
LLVM_NEW=$(bump_patch "$LLVM_CUR")
LLVM_MAJOR_NEW=$((LLVM_MAJOR_CUR + 1))
GIT_NEW=$(bump_patch "$GIT_CUR")
SEVENZIP_NEW=$((SEVENZIP_CUR + 1))
UV_NEW=$(bump_patch "$UV_CUR")

echo "== check-versions no update =="
copy_repo
out=$(mktemp)
RUST_OVERRIDE=$RUST_CUR LLVM_OVERRIDE=$LLVM_CUR GIT_OVERRIDE=$GIT_CUR SEVENZIP_OVERRIDE=$SEVENZIP_CUR UV_OVERRIDE=$UV_CUR GITHUB_OUTPUT="$out" ./scripts/check-versions.sh >/tmp/check-no-update.txt
grep -Fx "has_update=false" "$out"

echo "== check-versions git/7zip/uv only do not trigger =="
copy_repo
out=$(mktemp)
RUST_OVERRIDE=$RUST_CUR LLVM_OVERRIDE=$LLVM_CUR GIT_OVERRIDE=$GIT_NEW SEVENZIP_OVERRIDE=$SEVENZIP_NEW UV_OVERRIDE=$UV_NEW GITHUB_OUTPUT="$out" ./scripts/check-versions.sh >/tmp/check-tools-only.txt
grep -Fx "has_update=false" "$out"
! grep -Fq -- "- Git:" "$out"
! grep -Fq -- "- 7-Zip:" "$out"
! grep -Fq -- "- uv:" "$out"

echo "== check-versions update available =="
copy_repo
out=$(mktemp)
RUST_OVERRIDE=$RUST_NEW LLVM_OVERRIDE=$LLVM_NEW GIT_OVERRIDE=$GIT_NEW SEVENZIP_OVERRIDE=$SEVENZIP_NEW UV_OVERRIDE=$UV_NEW GITHUB_OUTPUT="$out" ./scripts/check-versions.sh >/tmp/check-update.txt
grep -Fx "has_update=true" "$out"
grep -F -- "- Rust: $RUST_CUR → $RUST_NEW" "$out"
grep -F -- "- LLVM: $LLVM_CUR → $LLVM_NEW" "$out"
grep -F -- "- Git: $GIT_CUR → $GIT_NEW" "$out"
grep -F -- "- 7-Zip: $SEVENZIP_CUR → $SEVENZIP_NEW" "$out"
grep -F -- "- uv: $UV_CUR → $UV_NEW" "$out"

echo "== update-versions applies patch update =="
copy_repo
RUST_CURRENT=$RUST_CUR \
RUST_LATEST=$RUST_NEW \
LLVM_CURRENT=$LLVM_CUR \
LLVM_LATEST=$LLVM_NEW \
LLVM_MAJOR=$LLVM_MAJOR_CUR \
GIT_CURRENT=$GIT_CUR \
GIT_LATEST=$GIT_NEW \
SEVENZIP_CURRENT=$SEVENZIP_CUR \
SEVENZIP_LATEST=$SEVENZIP_NEW \
UV_CURRENT=$UV_CUR \
UV_LATEST=$UV_NEW \
./scripts/update-versions.sh >/tmp/update-versions-patch.txt
grep -F "ARG RUST_VERSION=$RUST_NEW" linux/Dockerfile
grep -F "ARG RUST_VERSION=$RUST_NEW" windows/Dockerfile
grep -F "ARG LLVM_VERSION=$LLVM_MAJOR_CUR" linux/Dockerfile
grep -F "ARG LLVM_VERSION=$LLVM_NEW" windows/Dockerfile
grep -F "ARG GIT_VERSION=$GIT_NEW" windows/Dockerfile
grep -F "ARG SEVENZIP_VERSION=$SEVENZIP_NEW" windows/Dockerfile
grep -F "astral-sh/uv:$UV_NEW " linux/Dockerfile

echo "== update-versions applies llvm major update =="
copy_repo
RUST_CURRENT=$RUST_CUR \
RUST_LATEST=$RUST_CUR \
LLVM_CURRENT=$LLVM_CUR \
LLVM_LATEST=$LLVM_MAJOR_NEW.1.0 \
LLVM_MAJOR=$LLVM_MAJOR_NEW \
GIT_CURRENT=$GIT_CUR \
GIT_LATEST=$GIT_CUR \
SEVENZIP_CURRENT=$SEVENZIP_CUR \
SEVENZIP_LATEST=$SEVENZIP_CUR \
UV_CURRENT=$UV_CUR \
UV_LATEST=$UV_CUR \
./scripts/update-versions.sh >/tmp/update-versions-major.txt
grep -F "ARG LLVM_VERSION=$LLVM_MAJOR_NEW" linux/Dockerfile
grep -F "ARG LLVM_VERSION=$LLVM_MAJOR_NEW.1.0" windows/Dockerfile

echo "== validate-urls =="
copy_repo
./scripts/validate-urls.sh | tee /tmp/validate-urls.txt >/dev/null
grep -F "https://aka.ms/vs/17/release/channel" /tmp/validate-urls.txt
grep -F "https://apt.llvm.org/llvm-snapshot.gpg.key" /tmp/validate-urls.txt
grep -F "https://sh.rustup.rs" /tmp/validate-urls.txt
grep -F "All URLs validated successfully" /tmp/validate-urls.txt

echo "== clean-container workflow script tests passed =="
'