#!/usr/bin/env bash
set -euo pipefail

# Upload packages to Cloudsmith using the official CLI
#
# Required environment variables:
#   CLOUDSMITH_API_KEY - API key for authentication
#
# Usage:
#   upload_to_cloudsmith.sh --org ORG --repo REPO --distribution DISTRO/CODENAME \
#                           --local-path DIR --globs PATTERN [--tags TAG1,TAG2] [--republish]

ORGANIZATION=""
REPOSITORY=""
DISTRIBUTION=""
LOCAL_PATH=""
GLOBS=""
TAGS=""
REPUBLISH=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --org|--organization)
            ORGANIZATION="$2"
            shift 2
            ;;
        --repo|--repository)
            REPOSITORY="$2"
            shift 2
            ;;
        --distribution)
            DISTRIBUTION="$2"
            shift 2
            ;;
        --local-path)
            LOCAL_PATH="$2"
            shift 2
            ;;
        --globs)
            GLOBS="$2"
            shift 2
            ;;
        --tags)
            TAGS="$2"
            shift 2
            ;;
        --republish)
            REPUBLISH="--republish"
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

if [[ -z "$ORGANIZATION" || -z "$REPOSITORY" || -z "$DISTRIBUTION" || -z "$LOCAL_PATH" || -z "$GLOBS" ]]; then
    echo "Error: Missing required arguments" >&2
    echo "Usage: $0 --org ORG --repo REPO --distribution DISTRO/CODENAME --local-path DIR --globs PATTERN [--tags TAGS] [--republish]" >&2
    exit 1
fi

if [[ -z "${CLOUDSMITH_API_KEY:-}" ]]; then
    echo "Error: CLOUDSMITH_API_KEY environment variable is not set" >&2
    exit 1
fi

get_package_type() {
    local filename="$1"
    case "$filename" in
        *.deb) echo "deb" ;;
        *.rpm) echo "rpm" ;;
        *) echo "raw" ;;
    esac
}

echo "Local path:"
echo "    $LOCAL_PATH"
echo ""

cd "$LOCAL_PATH"

shopt -s nullglob
files=($GLOBS)
shopt -u nullglob

if [[ ${#files[@]} -eq 0 ]]; then
    echo "No files matching pattern: $GLOBS"
    exit 0
fi

echo "Files:"
for f in "${files[@]}"; do
    echo "    $f"
done
echo ""

errors=0
for filepath in "${files[@]}"; do
    filename=$(basename "$filepath")
    pkg_type=$(get_package_type "$filename")

    echo "Upload file: $filename"

    tag_args=""
    if [[ -n "$TAGS" ]]; then
        tag_args="--tags $TAGS"
    fi

    # Build the target path based on package type
    if [[ "$pkg_type" == "deb" || "$pkg_type" == "rpm" ]]; then
        target="${ORGANIZATION}/${REPOSITORY}/${DISTRIBUTION}"
    else
        target="${ORGANIZATION}/${REPOSITORY}"
    fi

    if cloudsmith push "$pkg_type" "$target" "$filepath" $REPUBLISH $tag_args --no-wait-for-sync; then
        echo "    OK"
    else
        echo "    Error: Upload failed"
        ((errors++))
    fi
done

if [[ $errors -gt 0 ]]; then
    echo ""
    echo "Failed to upload $errors file(s)" >&2
    exit 1
fi

echo ""
echo "All files uploaded successfully"
