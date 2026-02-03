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

tmux_kill_window() {
  local session="$1"
  local window="$2"
  tmux kill-window -t "$session:$window" >/dev/null 2>&1 || true
}

tmux_kill_pane() {
  local pane_id="$1"
  tmux kill-pane -t "$pane_id" >/dev/null 2>&1 || true
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

# ============================================================================
# Pane Layout Management
# ============================================================================
# Layout: Control pane at top, worker panes across the bottom
#
#   ┌─────────────────────────────────────────┐
#   │              Control (top)              │
#   ├─────────────────────────────────────────┤
#   │  Worker 1  │  Worker 2  │  Worker 3     │
#   └─────────────────────────────────────────┘
#
# Control takes ~30% height, workers split the bottom ~70%
#
# Pane tracking is stored in a temp file for cross-process persistence.

# Get the pane tracking file path for a session
_tmux_pane_file() {
  local session="$1"
  echo "/tmp/meta-panes-${session}.txt"
}

# Initialize layout: create the control pane and prepare for workers
tmux_init_layout() {
  local session="$1"
  local pane_file
  pane_file=$(_tmux_pane_file "$session")
  rm -f "$pane_file" 2>/dev/null || true
  touch "$pane_file"
}

# Get worker count from pane file
_tmux_get_worker_count() {
  local session="$1"
  local pane_file
  pane_file=$(_tmux_pane_file "$session")
  if [[ -f "$pane_file" ]]; then
    wc -l < "$pane_file" | tr -d ' '
  else
    echo "0"
  fi
}

# Get pane ID for a step
_tmux_get_pane_id() {
  local session="$1"
  local step_num="$2"
  local pane_file
  pane_file=$(_tmux_pane_file "$session")
  if [[ -f "$pane_file" ]]; then
    grep "^${step_num}:" "$pane_file" 2>/dev/null | cut -d: -f2
  fi
}

# Store pane ID for a step
_tmux_set_pane_id() {
  local session="$1"
  local step_num="$2"
  local pane_id="$3"
  local pane_file
  pane_file=$(_tmux_pane_file "$session")
  echo "${step_num}:${pane_id}" >> "$pane_file"
}

# Remove pane ID for a step
_tmux_remove_pane_id() {
  local session="$1"
  local step_num="$2"
  local pane_file
  pane_file=$(_tmux_pane_file "$session")
  if [[ -f "$pane_file" ]]; then
    local tmp_file="${pane_file}.tmp"
    grep -v "^${step_num}:" "$pane_file" > "$tmp_file" 2>/dev/null || true
    mv "$tmp_file" "$pane_file"
  fi
}

# Get all pane IDs (just the IDs, not step numbers)
_tmux_get_all_pane_ids() {
  local session="$1"
  local pane_file
  pane_file=$(_tmux_pane_file "$session")
  if [[ -f "$pane_file" ]]; then
    cut -d: -f2 "$pane_file" 2>/dev/null
  fi
}

# Create a worker pane for a step
# Sets TMUX_LAST_PANE_ID to the new pane's ID
TMUX_LAST_PANE_ID=""
tmux_create_worker_pane() {
  local session="$1"
  local step_num="$2"
  local command="$3"

  local worker_count
  worker_count=$(_tmux_get_worker_count "$session")
  local pane_id

  if [[ "$worker_count" -eq 0 ]]; then
    # First worker: split control pane vertically (control top 30%, worker bottom 70%)
    pane_id=$(tmux split-window -v -t "${session}:0.0" -p 70 -P -F '#{pane_id}' "$command")
  else
    # Additional workers: split the last worker pane horizontally
    local last_pane
    last_pane=$(_tmux_get_all_pane_ids "$session" | tail -1)

    if [[ -n "$last_pane" ]]; then
      # Split horizontally (side by side)
      pane_id=$(tmux split-window -h -t "$last_pane" -P -F '#{pane_id}' "$command")
    else
      # Fallback: split from control pane
      pane_id=$(tmux split-window -v -t "${session}:0.0" -p 70 -P -F '#{pane_id}' "$command")
    fi

    # Rebalance layout after adding new pane
    tmux_rebalance_layout "$session"
  fi

  _tmux_set_pane_id "$session" "$step_num" "$pane_id"
  TMUX_LAST_PANE_ID="$pane_id"
}

# Remove a worker pane when step completes
tmux_remove_worker_pane() {
  local session="$1"
  local step_num="$2"

  local pane_id
  pane_id=$(_tmux_get_pane_id "$session" "$step_num")

  if [[ -n "$pane_id" ]]; then
    tmux kill-pane -t "$pane_id" >/dev/null 2>&1 || true
    _tmux_remove_pane_id "$session" "$step_num"

    # Rebalance remaining panes
    local remaining
    remaining=$(_tmux_get_worker_count "$session")
    if [[ "$remaining" -gt 0 ]]; then
      tmux_rebalance_layout "$session"
    fi
  fi
}

# Rebalance layout: control on top, workers evenly split on bottom
tmux_rebalance_layout() {
  local session="$1"

  local worker_count
  worker_count=$(_tmux_get_worker_count "$session")

  if [[ "$worker_count" -eq 0 ]]; then
    return 0
  fi

  # Get window dimensions
  local win_height
  local win_width
  win_height=$(tmux display-message -t "$session" -p '#{window_height}' 2>/dev/null || echo "40")
  win_width=$(tmux display-message -t "$session" -p '#{window_width}' 2>/dev/null || echo "120")

  # Control gets 30% of height (min 8 lines)
  local control_height=$((win_height * 30 / 100))
  if [[ $control_height -lt 8 ]]; then
    control_height=8
  fi

  # Resize control pane (pane 0)
  tmux resize-pane -t "${session}:0.0" -y "$control_height" >/dev/null 2>&1 || true

  # Evenly distribute worker panes horizontally
  local worker_width=$((win_width / worker_count))
  local pane_ids
  pane_ids=$(_tmux_get_all_pane_ids "$session")
  local i=0
  local count=$worker_count

  while IFS= read -r pane_id; do
    if [[ -n "$pane_id" && $i -lt $((count - 1)) ]]; then
      tmux resize-pane -t "$pane_id" -x "$worker_width" >/dev/null 2>&1 || true
    fi
    i=$((i + 1))
  done <<< "$pane_ids"
}

# Get count of active worker panes
tmux_worker_count() {
  local session="$1"
  _tmux_get_worker_count "$session"
}

# Check if a worker pane exists for a step
tmux_has_worker_pane() {
  local session="$1"
  local step_num="$2"
  local pane_id
  pane_id=$(_tmux_get_pane_id "$session" "$step_num")
  [[ -n "$pane_id" ]]
}

# Cleanup pane tracking file when session ends
tmux_cleanup_layout() {
  local session="$1"
  local pane_file
  pane_file=$(_tmux_pane_file "$session")
  rm -f "$pane_file" 2>/dev/null || true
}
