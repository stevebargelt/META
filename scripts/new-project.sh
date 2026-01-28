#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: new-project.sh <project-name> [--base <path>] [--tool <claude|codex>] [--task <desc>] [--pipeline <name>] [--unsafe] [--no-orchestrate] [--kickoff] [--launch] [--launch-cmd <cmd>] [--open] [--git] [--no-git]

Creates a new project folder and prints the kickoff prompt.
Kickoff will ask questions, write the agent config, then hand off to PM for PRD.

Examples:
  ./scripts/new-project.sh my-app
  ./scripts/new-project.sh my-app --base ~/work --git
  ./scripts/new-project.sh my-app --tool codex --kickoff
  ./scripts/new-project.sh my-app --task "Build a habit tracker" --unsafe
  ./scripts/new-project.sh my-app --no-git
USAGE
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

PROJECT_NAME="$1"
shift

BASE_DIR="${HOME}/code"
INIT_GIT=true
TOOL=""
AGENT_FILE="AGENTS.md"
LAUNCH=false
LAUNCH_CMD=""
OPEN_FILE=false
ORCHESTRATE=true
PIPELINE="project"
TASK=""
UNSAFE=false
declare -a CLI_ARGS=()

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
    --task)
      TASK="$2"
      shift 2
      ;;
    --pipeline)
      PIPELINE="$2"
      shift 2
      ;;
    --unsafe)
      UNSAFE=true
      shift
      ;;
    --no-orchestrate)
      ORCHESTRATE=false
      shift
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
    --no-git)
      INIT_GIT=false
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

README_FILE="${PROJECT_DIR}/README.md"
README_TEMPLATE="${SCRIPT_DIR}/../prompts/readme-template.md"
if [[ ! -f "$README_FILE" ]]; then
  if [[ -f "$README_TEMPLATE" ]]; then
    escaped_name=$(printf '%s' "$PROJECT_NAME" | sed 's/[\\/&]/\\\\&/g')
    sed "s/\\[Project Name\\]/${escaped_name}/g" "$README_TEMPLATE" > "$README_FILE"
  else
    cat > "$README_FILE" <<EOF
# ${PROJECT_NAME}

[Add project description]
EOF
  fi
fi

ENV_EXAMPLE="${PROJECT_DIR}/.env.example"
if [[ ! -f "$ENV_EXAMPLE" ]]; then
  cat > "$ENV_EXAMPLE" <<'EOF'
# Copy to .env and fill values
# EXAMPLE_VAR=example
EOF
fi

CI_FILE="${PROJECT_DIR}/.github/workflows/ci.yml"
if [[ ! -f "$CI_FILE" ]]; then
  mkdir -p "${PROJECT_DIR}/.github/workflows"
  CI_TEMPLATE="${SCRIPT_DIR}/../patterns/deployment/ci-pipeline-node.md"
  if [[ -f "$CI_TEMPLATE" ]]; then
    awk 'BEGIN{in=0} /^```yaml/{in=1;next} /^```/{if(in){exit}} in{print}' "$CI_TEMPLATE" > "$CI_FILE"
  else
    cat > "$CI_FILE" <<'EOF'
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: echo "CI stub. Configure per META/patterns/deployment/ci-pipeline-node.md"
EOF
  fi
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

if [[ "$ORCHESTRATE" == false ]]; then
  cat <<EOF

Next: run kickoff in your chat:

$(cat "$KICKOFF_FILE")
EOF
else
  echo ""
  echo "Kickoff prompt saved to ${KICKOFF_FILE} (orchestration will run kickoff)."
fi

if [[ "$OPEN_FILE" == true ]]; then
  if [[ -n "${EDITOR:-}" ]]; then
    "$EDITOR" "$KICKOFF_FILE"
  else
    echo "EDITOR not set; printing kickoff file:"
    cat "$KICKOFF_FILE"
  fi
fi

if [[ "$ORCHESTRATE" == true ]]; then
  if [[ -z "$TASK" ]]; then
    TASK="Project kickoff: define goals, users, scope, and success metrics."
  fi

  META_CMD="${SCRIPT_DIR}/meta"
  if [[ ! -x "$META_CMD" ]]; then
    echo "meta CLI not found or not executable: $META_CMD" >&2
    exit 1
  fi

  CLI_ARGS=()
  if [[ -n "$TOOL" ]]; then
    CLI_ARGS+=(--cli "$TOOL")
  fi
  if [[ "$UNSAFE" == true ]]; then
    CLI_ARGS+=(--unsafe)
  fi

  echo ""
  echo "Starting orchestration pipeline: ${PIPELINE}"
  "$META_CMD" run "$PIPELINE" --project "$PROJECT_DIR" --task "$TASK" ${CLI_ARGS[@]+"${CLI_ARGS[@]}"}
  exit 0
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
