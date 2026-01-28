#!/usr/bin/env bash

# Gate prompts

gate_prompt() {
  local message="$1"
  local prompt="${2:-Approve? [y/n/r(retry)/s(skip)] (review above)} "

  if [[ "${META_AUTO_APPROVE:-}" == "1" ]]; then
    printf "\n%s\n" "$message" >&2
    printf "%s\n" "Auto-approve enabled." >&2
    echo "approve"
    return 0
  fi

  while true; do
    printf "\n%s\n" "$message" >&2
    read -r -p "$prompt" choice
    case "$choice" in
      y|Y)
        echo "approve"
        return 0
        ;;
      n|N)
        echo "abort"
        return 0
        ;;
      r|R)
        echo "retry"
        return 0
        ;;
      s|S)
        echo "skip"
        return 0
        ;;
      *)
        printf "%s\n" "Please enter y, n, r, or s." >&2
        ;;
    esac
  done
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
