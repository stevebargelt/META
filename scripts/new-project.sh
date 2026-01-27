#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: new-project.sh <project-name> [--base <path>] [--tool <claude|codex>] [--kickoff] [--launch] [--launch-cmd <cmd>] [--open] [--git]

Creates a new project folder and prints the kickoff prompt.
Kickoff will ask questions, write the agent config, then hand off to PM for PRD.

Examples:
  ./scripts/new-project.sh my-app
  ./scripts/new-project.sh my-app --base ~/work --git
  ./scripts/new-project.sh my-app --tool codex --kickoff
USAGE
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

PROJECT_NAME="$1"
shift

BASE_DIR="${HOME}/code"
INIT_GIT=false
TOOL=""
AGENT_FILE="AGENTS.md"
LAUNCH=false
LAUNCH_CMD=""
OPEN_FILE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)
      BASE_DIR="$2"
      shift 2
      ;;
    --tool)
      TOOL="$2"
      shift 2
      ;;
    --launch)
      LAUNCH=true
      shift
      ;;
    --kickoff)
      LAUNCH=true
      shift
      ;;
    --launch-cmd)
      LAUNCH_CMD="$2"
      shift 2
      ;;
    --open)
      OPEN_FILE=true
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

PROJECT_DIR="${BASE_DIR}/${PROJECT_NAME}"

if [[ -n "$TOOL" ]]; then
  case "$TOOL" in
    claude|codex)
      ;;
    *)
      echo "Unknown tool: $TOOL (use 'claude' or 'codex')" >&2
      exit 1
      ;;
  esac
fi

if [[ -e "$PROJECT_DIR" ]]; then
  echo "Project directory already exists: ${PROJECT_DIR}" >&2
  exit 1
fi

mkdir -p "${PROJECT_DIR}/docs"

if [[ ! -f "${PROJECT_DIR}/${AGENT_FILE}" ]]; then
  cat > "${PROJECT_DIR}/${AGENT_FILE}" <<'EOF'
# Project Name

Inherits: ../META/agents/base.md

[Filled by kickoff]
EOF
fi

if [[ ! -e "${PROJECT_DIR}/CLAUDE.md" ]]; then
  (cd "$PROJECT_DIR" && ln -s "${AGENT_FILE}" CLAUDE.md)
elif [[ -L "${PROJECT_DIR}/CLAUDE.md" ]]; then
  :
else
  echo "Warning: CLAUDE.md exists and is not a symlink. Leaving as-is." >&2
fi

if [[ "$INIT_GIT" == true ]]; then
  (cd "$PROJECT_DIR" && git init >/dev/null)
fi

echo "Created project: ${PROJECT_DIR}"
if [[ "$INIT_GIT" == true ]]; then
  echo "Git: initialized"
fi

KICKOFF_FILE="${PROJECT_DIR}/KICKOFF.md"
cat > "$KICKOFF_FILE" <<EOF
Start a project kickoff using META/prompts/kickoff.md
Project path: ${PROJECT_DIR}
Tool: ${TOOL:-unspecified}
EOF

cat <<EOF

Next: run kickoff in your chat:

$(cat "$KICKOFF_FILE")
EOF

if [[ "$OPEN_FILE" == true ]]; then
  if [[ -n "${EDITOR:-}" ]]; then
    "$EDITOR" "$KICKOFF_FILE"
  else
    echo "EDITOR not set; printing kickoff file:"
    cat "$KICKOFF_FILE"
  fi
fi

if [[ "$LAUNCH" == true ]]; then
  if [[ -z "$LAUNCH_CMD" ]]; then
    if [[ "$TOOL" == "claude" ]]; then
      LAUNCH_CMD="claude"
    elif [[ "$TOOL" == "codex" ]]; then
      LAUNCH_CMD="codex"
    else
      LAUNCH_CMD=""
    fi
  fi

  if [[ -z "$LAUNCH_CMD" ]]; then
    echo "Launch requested but no command provided. Use --launch-cmd <cmd>." >&2
    exit 1
  fi

  if command -v "$LAUNCH_CMD" >/dev/null 2>&1; then
    PROMPT_TEXT="$(cat "$KICKOFF_FILE")"
    (cd "$PROJECT_DIR" && "$LAUNCH_CMD" "$PROMPT_TEXT")
  else
    echo "Launch command not found: $LAUNCH_CMD" >&2
    exit 1
  fi
fi
