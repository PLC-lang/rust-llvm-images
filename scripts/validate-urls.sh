#!/bin/bash
# Validates that all URLs in Dockerfiles are accessible
# Extracts literal URLs from Dockerfiles and checks them with curl

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Extract literal URLs from Dockerfiles, substituting ARG values
validate_dockerfile() {
    local dockerfile="$1"
    local arch
    local key
    local value
    local url
    local resolved_url
    local previous_url
    local status

    arch="$(uname -m)"
    echo "Validating $dockerfile..."

    # Extract ARG values into associative array
    declare -A args=()
    while IFS='=' read -r key value; do
        args["$key"]="$value"
    done < <(grep -oP 'ARG\s+\K[A-Z0-9_]+=[^[:space:]]+' "$dockerfile" || true)

    # Extract all literal URLs so we also validate ARG URL definitions and RUN downloads
    mapfile -t urls < <(grep -oP 'https?://[^[:space:]"`]+' "$dockerfile" | sort -u || true)

    for url in "${urls[@]}"; do
        resolved_url="$url"

        # Resolve nested ARG references and the $(uname -m) pattern used in linux/Dockerfile
        for _ in 1 2 3 4 5; do
            previous_url="$resolved_url"

            for key in "${!args[@]}"; do
                resolved_url="${resolved_url//\$\{$key\}/${args[$key]}}"
                resolved_url="${resolved_url//\$$key/${args[$key]}}"
            done

            resolved_url="${resolved_url//\$\(uname -m\)/$arch}"

            if [[ "$resolved_url" == "$previous_url" ]]; then
                break
            fi
        done

        if [[ "$resolved_url" == *'$'* ]]; then
            echo "  Skipping unresolved URL template: $resolved_url"
            continue
        fi

        echo -n "  Checking $resolved_url ... "

        # Use HEAD request with follow redirects
        status=$(curl -s -o /dev/null -w "%{http_code}" -L --head --max-time 30 "$resolved_url" 2>/dev/null || echo "000")

        if [[ "$status" =~ ^2 ]]; then
            echo "OK ($status)"
        else
            echo "FAILED ($status)"
            FAILED_URLS+=("$resolved_url")
        fi
    done
}

FAILED_URLS=()

# Validate all Dockerfiles
for dockerfile in "$ROOT_DIR"/*/Dockerfile; do
    if [[ -f "$dockerfile" ]]; then
        validate_dockerfile "$dockerfile"
    fi
done

echo ""

if [[ ${#FAILED_URLS[@]} -gt 0 ]]; then
    echo "ERROR: ${#FAILED_URLS[@]} URL(s) failed validation:"
    for url in "${FAILED_URLS[@]}"; do
        echo "  - $url"
    done
    exit 1
else
    echo "All URLs validated successfully"
fi
