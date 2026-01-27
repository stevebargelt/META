#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: new-project.sh <project-name> [--base <path>] [--agent-file <name>] [--no-prd] [--git]

Creates a new project folder, copies AGENTS.md from META templates,
and (optionally) creates docs/PRD.md. Can initialize git if requested.

Examples:
  ./scripts/new-project.sh my-app
  ./scripts/new-project.sh my-app --base ~/work --git
  ./scripts/new-project.sh my-app --no-prd
USAGE
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

PROJECT_NAME="$1"
shift

BASE_DIR="${HOME}/code"
AGENT_FILE="AGENTS.md"
CREATE_PRD=true
INIT_GIT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)
      BASE_DIR="$2"
      shift 2
      ;;
    --agent-file)
      AGENT_FILE="$2"
      shift 2
      ;;
    --no-prd)
      CREATE_PRD=false
      shift
      ;;
    --git)
      INIT_GIT=true
      shift
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

PROJECT_DIR="${BASE_DIR}/${PROJECT_NAME}"

if [[ -e "$PROJECT_DIR" ]]; then
  echo "Project directory already exists: ${PROJECT_DIR}" >&2
  exit 1
fi

mkdir -p "$PROJECT_DIR"
cp "${META_DIR}/prompts/project-template.md" "${PROJECT_DIR}/${AGENT_FILE}"

if [[ "$CREATE_PRD" == true ]]; then
  mkdir -p "${PROJECT_DIR}/docs"
  cp "${META_DIR}/prompts/prd-template.md" "${PROJECT_DIR}/docs/PRD.md"
fi

if [[ "$INIT_GIT" == true ]]; then
  (cd "$PROJECT_DIR" && git init >/dev/null)
fi

echo "Created project: ${PROJECT_DIR}"
echo "Agent config: ${PROJECT_DIR}/${AGENT_FILE}"
if [[ "$CREATE_PRD" == true ]]; then
  echo "PRD: ${PROJECT_DIR}/docs/PRD.md"
fi
if [[ "$INIT_GIT" == true ]]; then
  echo "Git: initialized"
fi

echo "Next: cd ${PROJECT_DIR} and fill in ${AGENT_FILE}"
