#!/usr/bin/env bash

# State file helpers

state_set() {
  local file="$1"
  local key="$2"
  local value="$3"

  local tmp
  tmp="${file}.tmp"

  if [[ -f "$file" ]]; then
    awk -v k="$key" -v v="$value" 'BEGIN{found=0} {
      if ($0 ~ "^" k "=") {
        print k "=" v
        found=1
      } else {
        print $0
      }
    } END {
      if (!found) {
        print k "=" v
      }
    }' "$file" > "$tmp"
  else
    printf "%s=%s\n" "$key" "$value" > "$tmp"
  fi

  mv "$tmp" "$file"
}

state_get() {
  local file="$1"
  local key="$2"

  if [[ ! -f "$file" ]]; then
    return 1
  fi

  local line
  line=$(grep -E "^${key}=" "$file" | tail -n 1 || true)
  if [[ -z "$line" ]]; then
    return 1
  fi

  printf "%s" "${line#*=}"
}

state_latest_file() {
  local project="$1"
  local state_dir="$project/.meta"
  if [[ ! -d "$state_dir" ]]; then
    return 1
  fi

  local latest
  latest=$(ls -t "$state_dir"/state.* 2>/dev/null | head -n 1 || true)
  if [[ -z "$latest" ]]; then
    return 1
  fi

  printf "%s" "$latest"
}

state_print_summary() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "State file not found: $file" >&2
    return 1
  fi

  local pipeline run_id session started current_step
  pipeline=$(state_get "$file" "pipeline" || true)
  run_id=$(state_get "$file" "run_id" || true)
  session=$(state_get "$file" "session" || true)
  started=$(state_get "$file" "started" || true)
  current_step=$(state_get "$file" "current_step" || true)

  echo "Pipeline: ${pipeline:-unknown}"
  echo "Run ID: ${run_id:-unknown}"
  echo "Session: ${session:-unknown}"
  echo "Started: ${started:-unknown}"
  echo "Current step: ${current_step:-unknown}"
  echo ""

  grep -E '^step_[0-9]+=' "$file" || true
}

# Set group state
state_set_group() {
  local state_file="$1"
  local group_name="$2"
  local status="$3"  # running|done|failed

  state_set "$state_file" "group_${group_name}" "$status"
  state_set "$state_file" "group_${group_name}_time" "$(date +%s)"
}

# Get group state
state_get_group() {
  local state_file="$1"
  local group_name="$2"

  state_get "$state_file" "group_${group_name}" 2>/dev/null || echo "pending"
}

# Set wave state
state_set_wave() {
  local state_file="$1"
  local wave_num="$2"
  local status="$3"  # running|done|failed
  local groups="$4"  # Space-separated group names

  state_set "$state_file" "wave_${wave_num}" "$status"
  state_set "$state_file" "wave_${wave_num}_groups" "$groups"
  state_set "$state_file" "wave_${wave_num}_time" "$(date +%s)"
}

# Get wave state
state_get_wave() {
  local state_file="$1"
  local wave_num="$2"

  state_get "$state_file" "wave_${wave_num}" 2>/dev/null || echo "pending"
}
