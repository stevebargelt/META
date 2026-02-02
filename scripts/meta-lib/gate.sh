#!/usr/bin/env bash

# Gate prompts

# Global to track gate wait time for current call
GATE_WAIT_SEC=0

# Accumulate gate wait time to state file
gate_accumulate_wait() {
  local state_file="$1"
  local current_total
  current_total=$(state_get "$state_file" "gate_wait_total" 2>/dev/null || echo "0")
  local new_total=$((current_total + GATE_WAIT_SEC))
  state_set "$state_file" "gate_wait_total" "$new_total"
}

gate_prompt() {
  local message="$1"
  local log_file="${2:-}"
  local prompt="${3:-Approve? [y/n/r(retry)/s(skip)]}"

  local gate_start_epoch
  gate_start_epoch="$(date +%s)"

  if [[ "${META_AUTO_APPROVE:-}" == "1" ]]; then
    printf "\n%s\n" "$message" >&2
    printf "%s\n" "Auto-approve enabled." >&2
    GATE_WAIT_SEC=0
    echo "approve"
    return 0
  fi

  # Show log summary if log file provided
  if [[ -n "$log_file" && -f "$log_file" ]]; then
    printf "\n─── Last 20 lines of %s ───\n" "$(basename "$log_file")" >&2
    tail -20 "$log_file" >&2
    printf "────────────────────────────────────\n\n" >&2
  fi

  local result=""
  while true; do
    printf "%s\n" "$message" >&2
    read -r -p "$prompt " choice
    case "$choice" in
      y|Y)
        result="approve"
        break
        ;;
      n|N)
        result="abort"
        break
        ;;
      r|R)
        result="retry"
        break
        ;;
      s|S)
        result="skip"
        break
        ;;
      *)
        printf "%s\n" "Please enter y, n, r, or s." >&2
        ;;
    esac
  done

  local gate_end_epoch
  gate_end_epoch="$(date +%s)"
  GATE_WAIT_SEC=$((gate_end_epoch - gate_start_epoch))

  echo "$result"
  return 0
}

quality_gate_check() {
  local project="$1"
  local script
  script="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/quality-gate.sh"
  if [[ -x "$script" ]]; then
    echo "Running quality gate checks..." >&2
    local output
    if output=$("$script" --project "$project" 2>&1); then
      printf "%s\n" "$output" >&2
      return 0
    else
      printf "%s\n" "$output" >&2
      echo "Quality gate FAILED." >&2
      return 1
    fi
  fi
  return 0
}

error_prompt() {
  local message="$1"
  local prompt="${2:-Retry? [r/s/a(abort)]} "

  while true; do
    printf "\n%s\n" "$message" >&2
    read -r -p "$prompt" choice
    case "$choice" in
      r|R)
        echo "retry"
        return 0
        ;;
      s|S)
        echo "skip"
        return 0
        ;;
      a|A)
        echo "abort"
        return 0
        ;;
      *)
        printf "%s\n" "Please enter r, s, or a." >&2
        ;;
    esac
  done
}
