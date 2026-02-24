#!/bin/bash
# Validates that all URLs in Dockerfiles are accessible
# Extracts URLs from ADD directives and checks them with curl

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Extract ADD URLs from Dockerfiles, substituting ARG values
validate_dockerfile() {
    local dockerfile="$1"
    local dir="$(dirname "$dockerfile")"
    local name="$(basename "$dir")"
    
    echo "Validating $dockerfile..."
    
    # Extract ARG values into associative array
    declare -A args
    while IFS='=' read -r key value; do
        args["$key"]="$value"
    done < <(grep -oP 'ARG \K[A-Z0-9_]+=[^\s]+' "$dockerfile" | sed 's/ARG //')
    
    # Extract ADD URLs and substitute variables
    local urls=$(grep -oP 'ADD\s+\Khttps?://[^\s]+' "$dockerfile" || true)
    
    for url in $urls; do
        # Substitute ${VAR} and $VAR patterns
        resolved_url="$url"
        for key in "${!args[@]}"; do
            resolved_url="${resolved_url//\$\{$key\}/${args[$key]}}"
            resolved_url="${resolved_url//\$$key/${args[$key]}}"
        done
        
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
