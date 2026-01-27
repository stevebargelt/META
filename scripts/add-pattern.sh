#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: add-pattern.sh <category> <pattern-name> [--ext <md|ts|js>]

Scaffolds a new pattern file in META/patterns/<category>/.

Examples:
  ./scripts/add-pattern.sh api rest-error-handling
  ./scripts/add-pattern.sh auth jwt-rotation --ext md
USAGE
}

if [[ $# -lt 2 ]]; then
  usage
  exit 1
fi

CATEGORY="$1"
PATTERN_NAME="$2"
shift 2

EXT="md"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --ext)
      EXT="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
META_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

PATTERNS_DIR="${META_DIR}/patterns/${CATEGORY}"
if [[ ! -d "$PATTERNS_DIR" ]]; then
  echo "Unknown category: ${CATEGORY}" >&2
  echo "Existing categories:" >&2
  ls -1 "${META_DIR}/patterns" >&2
  exit 1
fi

FILE_NAME="${PATTERN_NAME}"
if [[ "$FILE_NAME" != *.* ]]; then
  FILE_NAME="${FILE_NAME}.${EXT}"
fi

TARGET="${PATTERNS_DIR}/${FILE_NAME}"
if [[ -e "$TARGET" ]]; then
  echo "Pattern already exists: ${TARGET}" >&2
  exit 1
fi

cat > "$TARGET" <<EOF
# ${PATTERN_NAME}

**What:** [Brief description]
**When to use:** [Specific scenarios]
**Source:** [Project where proven]

## Implementation

[Pattern content]

## Example

[How it's used]

## Variations

[Common adaptations]
EOF

echo "Created pattern: ${TARGET}"
echo "Remember to update ${PATTERNS_DIR}/README.md"
