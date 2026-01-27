#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: retrospective.sh <project-name> [--date YYYY-MM]

Creates a dated retrospective file from META/learnings/retrospective-template.md.

Examples:
  ./scripts/retrospective.sh my-project
  ./scripts/retrospective.sh my-project --date 2026-01
USAGE
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

PROJECT_NAME="$1"
shift

DATE="$(date +%Y-%m)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --date)
      DATE="$2"
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

SLUG="$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')"
TARGET="${META_DIR}/learnings/${DATE}-${SLUG}.md"

if [[ -e "$TARGET" ]]; then
  echo "Retrospective already exists: ${TARGET}" >&2
  exit 1
fi

cp "${META_DIR}/learnings/retrospective-template.md" "$TARGET"
echo "Created retrospective: ${TARGET}"
