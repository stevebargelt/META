#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: agent.sh <agent-name> [--project <path>] [--stream <name>]

Creates a .meta/handoff.md (or .meta/handoff-<stream>.md) with a prefilled agent-handoff
template in the target project directory.

Examples:
  ./scripts/agent.sh architect
  ./scripts/agent.sh reviewer --project ~/code/my-project
  ./scripts/agent.sh debugger --stream api
USAGE
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

AGENT="$1"
shift

PROJECT_DIR="$(pwd)"
STREAM=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      PROJECT_DIR="$2"
      shift 2
      ;;
    --stream)
      STREAM="$2"
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

AGENT_FILE="${META_DIR}/agents/${AGENT}.md"
if [[ ! -f "$AGENT_FILE" ]]; then
  echo "Agent not found: ${AGENT_FILE}" >&2
  exit 1
fi

mkdir -p "$PROJECT_DIR/.meta"
HANDOFF_FILE="${PROJECT_DIR}/.meta/handoff${STREAM:+-${STREAM}}.md"

cat > "$HANDOFF_FILE" <<EOF
# Handoff

## Meta
- **Type:** agent-handoff
- **From:** [agent or model name]
- **To:** ${AGENT}
- **Timestamp:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")
- **Reason:** [one sentence]

## Project
[One sentence description]
**Stack:** [tech stack]
**AGENTS.md:** [path]

## State
**Working:** [what functions correctly]
**In Progress:** [what's partially done, with file:line references]

## Decisions
1. [Key decision with brief rationale]
2. [Another decision]

## Key Files
- \`path/to/file.js\` — [one-line explanation]
- \`path/to/other.js\` — [one-line explanation]
(3-7 files max)

## Next Step
[Single specific action. Not a list — one thing.]

## Context Budget
- **What was loaded:** [files/docs read this session]
- **What should NOT be reloaded:** [things that were irrelevant]
EOF

echo "Created ${HANDOFF_FILE}"
echo "Agent definition: ${AGENT_FILE}"
