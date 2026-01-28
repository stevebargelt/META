#!/usr/bin/env bash

# Tmux helpers

tmux_require() {
  if ! command -v tmux >/dev/null 2>&1; then
    echo "tmux is not installed or not in PATH" >&2
    return 1
  fi
  return 0
}

tmux_session_exists() {
  local session="$1"
  tmux has-session -t "$session" 2>/dev/null
}

tmux_create_session() {
  local session="$1"
  local window="$2"
  local command="$3"

  tmux new-session -d -s "$session" -n "$window" "$command"
  tmux set-option -t "$session" remain-on-exit on >/dev/null
  tmux set-option -t "$session" status-right "" >/dev/null
}

tmux_new_window() {
  local session="$1"
  local window="$2"
  local command="$3"

  tmux new-window -d -t "$session" -n "$window" "$command"
}

tmux_select_window() {
  local session="$1"
  local window="$2"
  tmux select-window -t "$session:$window" 2>/dev/null || true
}

# Split current pane and run command in the new pane
# Direction: "h" for horizontal (side-by-side), "v" for vertical (top/bottom)
tmux_split_pane() {
  local session="$1"
  local direction="${2:-v}"  # default vertical (top/bottom)
  local size="${3:-50}"      # percentage
  local command="$4"

  if [[ "$direction" == "h" ]]; then
    tmux split-window -h -t "$session" -p "$size" "$command"
  else
    tmux split-window -v -t "$session" -p "$size" "$command"
  fi
}

tmux_kill_session() {
  local session="$1"
  tmux kill-session -t "$session" >/dev/null 2>&1 || true
}

tmux_attach() {
  local session="$1"
  tmux attach -t "$session"
}

tmux_set_status() {
  local session="$1"
  local text="$2"
  tmux set-option -t "$session" status-right "$text" >/dev/null 2>&1 || true
}
