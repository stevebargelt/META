#!/usr/bin/env bash

# Handoff helpers

handoff_init() {
  local project="$1"
  local task="$2"
  local run_id="$3"
  local pipeline_name="$4"

  mkdir -p "$project/.meta"
  local file="$project/.meta/handoff.md"

  cat > "$file" <<EOF_HANDOFF
# Handoff

## Meta
- **Type:** agent-handoff
- **From:** user
- **To:** meta pipeline
- **Timestamp:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")
- **Run ID:** ${run_id}
- **Pipeline:** ${pipeline_name}

## Task
${task}

## Notes
- Project: ${project}
EOF_HANDOFF
}

handoff_step_file() {
  local project="$1"
  local step_num="$2"
  mkdir -p "$project/.meta"
  printf "%s/.meta/handoff-step-%s.md" "$project" "$step_num"
}

handoff_merge_step() {
  local project="$1"
  local run_id="$2"
  local step_num="$3"
  local agent="$4"

  local step_file
  step_file="$(handoff_step_file "$project" "$step_num")"
  if [[ ! -f "$step_file" ]]; then
    return 0
  fi

  local steps_dir="$project/.meta/steps/$run_id"
  local merged_flag="$steps_dir/step-${step_num}.merged"
  if [[ -f "$merged_flag" ]]; then
    return 0
  fi

  local handoff_main="$project/.meta/handoff.md"
  if [[ ! -f "$handoff_main" ]]; then
    touch "$handoff_main"
  fi

  {
    echo ""
    echo "## Parallel Step ${step_num} (${agent}) — $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    cat "$step_file"
  } >> "$handoff_main"

  touch "$merged_flag"
}
