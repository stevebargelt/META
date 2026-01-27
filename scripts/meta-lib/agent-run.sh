#!/usr/bin/env bash

# Agent runner helpers

AGENT_RUN_FILE=""
AGENT_EXIT_FILE=""
AGENT_PROMPT_FILE=""
AGENT_SYSTEM_FILE=""

agent_prepare_step() {
  local project="$1"
  local run_id="$2"
  local step_num="$3"
  local agent="$4"
  local cli="$5"
  local step_prompt="$6"
  local handoff_file="$7"
  local meta_dir="$8"
  local unsafe_flag="$9"
  local codex_flags="--sandbox workspace-write"
  if [[ -n "$unsafe_flag" ]]; then
    codex_flags="--sandbox danger-full-access"
  fi

  local steps_dir="$project/.meta/steps/$run_id"
  mkdir -p "$steps_dir"

  AGENT_PROMPT_FILE="$steps_dir/step-${step_num}.prompt"
  AGENT_SYSTEM_FILE="$steps_dir/step-${step_num}.system.md"
  AGENT_RUN_FILE="$steps_dir/step-${step_num}.run.sh"
  AGENT_EXIT_FILE="$steps_dir/step-${step_num}.exit"
  local log_file="$steps_dir/step-${step_num}.log"

  local agent_def="$meta_dir/agents/${agent}.md"
  if [[ ! -f "$agent_def" ]]; then
    echo "Agent definition not found: $agent_def" >&2
    return 1
  fi

  cat > "$AGENT_PROMPT_FILE" <<EOF_PROMPT
You are acting as the ${agent} agent.
Agent definition: ${agent_def}

First: read ${handoff_file}.

Task:
${step_prompt}

When complete:
- Update ${handoff_file} with your output.
- Summarize key decisions and files touched.
EOF_PROMPT

  cat "$agent_def" > "$AGENT_SYSTEM_FILE"

  cat > "$AGENT_RUN_FILE" <<EOF_RUN
#!/usr/bin/env bash
set -u

cd "$project"

exit_code=0
CLI="$cli"
PROMPT_FILE="$AGENT_PROMPT_FILE"
SYSTEM_FILE="$AGENT_SYSTEM_FILE"
EXIT_FILE="$AGENT_EXIT_FILE"
LOG_FILE="$log_file"
CODEX_FLAGS="$codex_flags"

if [[ "\$CLI" == "claude" ]]; then
  if claude -p "\$(cat "\$PROMPT_FILE")" --system-prompt "\$(cat "\$SYSTEM_FILE")" --allowedTools "Bash Edit Read Write Glob Grep" ${unsafe_flag} >"\$LOG_FILE" 2>&1; then
    exit_code=0
  else
    exit_code=\$?
  fi
elif [[ "\$CLI" == "claude-interactive" ]]; then
  claude "\$(cat "\$PROMPT_FILE")" --system-prompt "\$(cat "\$SYSTEM_FILE")" --allowedTools "Bash Edit Read Write Glob Grep" ${unsafe_flag}
  exit_code=\$?
elif [[ "\$CLI" == "codex" ]]; then
  if codex exec \$CODEX_FLAGS "\$(cat "\$PROMPT_FILE")" >"\$LOG_FILE" 2>&1; then
    exit_code=0
  else
    exit_code=\$?
  fi
elif [[ "\$CLI" == "codex-interactive" ]]; then
  codex \$CODEX_FLAGS "\$(cat "\$PROMPT_FILE")"
  exit_code=\$?
else
  echo "Unknown CLI: \$CLI" >"\$LOG_FILE" 2>&1
  exit_code=127
fi

printf "%s" "\$exit_code" > "\$EXIT_FILE"
exit "\$exit_code"
EOF_RUN

  chmod +x "$AGENT_RUN_FILE" >/dev/null 2>&1 || true

  return 0
}
