#!/usr/bin/env bash

# Gate prompts

gate_prompt() {
  local message="$1"
  local prompt="${2:-Approve? [y/n/r(retry)/s(skip)]} "

  while true; do
    echo ""
    echo "$message"
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
        echo "Please enter y, n, r, or s."
        ;;
    esac
  done
}

error_prompt() {
  local message="$1"
  local prompt="${2:-Retry? [r/s/a(abort)]} "

  while true; do
    echo ""
    echo "$message"
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
        echo "Please enter r, s, or a."
        ;;
    esac
  done
}
