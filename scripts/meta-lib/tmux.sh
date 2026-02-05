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
# Layout:
# - Main window keeps the control/orchestrator pane on top.
# - When PARALLEL_GROUP is set, each group gets its own tmux window.
#   Inside that window, a sub-manager pane stays on top, with workers split below.
#
#   Main window (session:0)
#   ┌─────────────────────────────────────────┐
#   │              Control (top)              │
#   └─────────────────────────────────────────┘
#
#   Group window (group-<name>)
#   ┌─────────────────────────────────────────┐
#   │         Sub manager (top)               │
#   ├─────────────────────────────────────────┤
#   │  Worker 1  │  Worker 2  │  Worker 3     │
#   └─────────────────────────────────────────┘
#
# Pane tracking is stored in a temp file for cross-process persistence.

# Get the pane tracking file path for a session
_tmux_pane_file() {
  local session="$1"
  echo "/tmp/meta-panes-${session}.txt"
}

# Group tracking file path for a session (group -> window -> sub-manager pane)
_tmux_group_file() {
  local session="$1"
  echo "/tmp/meta-groups-${session}.txt"
}

# Group worker tracking file path for a session (step -> group -> pane)
_tmux_group_workers_file() {
  local session="$1"
  echo "/tmp/meta-group-workers-${session}.txt"
}

# Initialize layout: create the control pane and prepare for workers
tmux_init_layout() {
  local session="$1"
  local pane_file
  pane_file=$(_tmux_pane_file "$session")
  rm -f "$pane_file" 2>/dev/null || true
  touch "$pane_file"
  rm -f "$(_tmux_group_file "$session")" 2>/dev/null || true
  rm -f "$(_tmux_group_workers_file "$session")" 2>/dev/null || true
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

# Remove pane ID by pane_id (not step number)
_tmux_remove_pane_id_by_pane_id() {
  local session="$1"
  local pane_id="$2"
  local pane_file
  pane_file=$(_tmux_pane_file "$session")
  if [[ -f "$pane_file" ]]; then
    local tmp_file="${pane_file}.tmp"
    grep -v ":${pane_id}$" "$pane_file" > "$tmp_file" 2>/dev/null || true
    mv "$tmp_file" "$pane_file"
  fi
}

# Group tracking helpers
_tmux_set_group_info() {
  local session="$1"
  local group="$2"
  local window_id="$3"
  local sub_pane="$4"
  local group_file
  group_file=$(_tmux_group_file "$session")

  if [[ -f "$group_file" ]]; then
    local tmp_file="${group_file}.tmp"
    awk -v g="$group" -v w="$window_id" -v s="$sub_pane" 'BEGIN{found=0} {
      if ($0 ~ "^" g ":") { print g ":" w ":" s; found=1 }
      else { print $0 }
    } END { if (!found) print g ":" w ":" s }' "$group_file" > "$tmp_file"
    mv "$tmp_file" "$group_file"
  else
    printf "%s:%s:%s\n" "$group" "$window_id" "$sub_pane" > "$group_file"
  fi
}

_tmux_get_group_window() {
  local session="$1"
  local group="$2"
  local group_file
  group_file=$(_tmux_group_file "$session")
  if [[ -f "$group_file" ]]; then
    grep -E "^${group}:" "$group_file" 2>/dev/null | head -n 1 | cut -d: -f2 || true
  fi
}

_tmux_get_group_sub_pane() {
  local session="$1"
  local group="$2"
  local group_file
  group_file=$(_tmux_group_file "$session")
  if [[ -f "$group_file" ]]; then
    grep -E "^${group}:" "$group_file" 2>/dev/null | head -n 1 | cut -d: -f3 || true
  fi
}

_tmux_group_exists() {
  local session="$1"
  local group="$2"
  local group_file
  group_file=$(_tmux_group_file "$session")
  [[ -f "$group_file" ]] && grep -qE "^${group}:" "$group_file" 2>/dev/null
}

_tmux_get_group_names() {
  local session="$1"
  local group_file
  group_file=$(_tmux_group_file "$session")
  if [[ -f "$group_file" ]]; then
    cut -d: -f1 "$group_file" 2>/dev/null
  fi
}

_tmux_add_group_worker() {
  local session="$1"
  local step_num="$2"
  local group="$3"
  local pane_id="$4"
  local workers_file
  workers_file=$(_tmux_group_workers_file "$session")
  printf "%s:%s:%s\n" "$step_num" "$group" "$pane_id" >> "$workers_file"
}

_tmux_remove_group_worker_by_step() {
  local session="$1"
  local step_num="$2"
  local workers_file
  workers_file=$(_tmux_group_workers_file "$session")
  if [[ -f "$workers_file" ]]; then
    local tmp_file="${workers_file}.tmp"
    grep -v "^${step_num}:" "$workers_file" > "$tmp_file" 2>/dev/null || true
    mv "$tmp_file" "$workers_file"
  fi
}

_tmux_remove_group_worker_by_pane_id() {
  local session="$1"
  local pane_id="$2"
  local workers_file
  workers_file=$(_tmux_group_workers_file "$session")
  if [[ -f "$workers_file" ]]; then
    local tmp_file="${workers_file}.tmp"
    grep -v ":${pane_id}$" "$workers_file" > "$tmp_file" 2>/dev/null || true
    mv "$tmp_file" "$workers_file"
  fi
}

_tmux_get_group_for_step() {
  local session="$1"
  local step_num="$2"
  local workers_file
  workers_file=$(_tmux_group_workers_file "$session")
  if [[ -f "$workers_file" ]]; then
    grep -E "^${step_num}:" "$workers_file" 2>/dev/null | head -n 1 | cut -d: -f2 || true
  fi
}

_tmux_get_group_worker_panes() {
  local session="$1"
  local group="$2"
  local workers_file
  workers_file=$(_tmux_group_workers_file "$session")
  if [[ -f "$workers_file" ]]; then
    grep -E "^[0-9]+:${group}:" "$workers_file" 2>/dev/null | cut -d: -f3
  fi
}

_tmux_get_group_worker_count() {
  local session="$1"
  local group="$2"
  local panes
  panes=$(_tmux_get_group_worker_panes "$session" "$group")
  if [[ -n "$panes" ]]; then
    printf "%s" "$panes" | wc -l | tr -d ' '
  else
    echo "0"
  fi
}

_tmux_get_last_group_worker_pane() {
  local session="$1"
  local group="$2"
  local panes
  panes=$(_tmux_get_group_worker_panes "$session" "$group")
  if [[ -n "$panes" ]]; then
    printf "%s" "$panes" | tail -n 1
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

_tmux_get_non_group_worker_panes() {
  local session="$1"
  local pane_file
  pane_file=$(_tmux_pane_file "$session")
  if [[ ! -f "$pane_file" ]]; then
    return 0
  fi

  local all_panes
  all_panes=$(cut -d: -f2 "$pane_file" 2>/dev/null)
  if [[ -z "$all_panes" ]]; then
    return 0
  fi

  local workers_file
  workers_file=$(_tmux_group_workers_file "$session")
  if [[ ! -f "$workers_file" ]]; then
    printf "%s" "$all_panes"
    return 0
  fi

  local group_panes
  group_panes=$(cut -d: -f3 "$workers_file" 2>/dev/null)
  if [[ -z "$group_panes" ]]; then
    printf "%s" "$all_panes"
    return 0
  fi

  printf "%s\n" "$all_panes" | grep -v -F -f <(printf "%s\n" "$group_panes") 2>/dev/null || true
}

# Clean up dead worker panes (prevents pane limit issues)
tmux_cleanup_dead_worker_panes() {
  local session="$1"

  local all_panes
  all_panes=$(tmux list-panes -a -F '#{session_name} #{pane_id} #{pane_dead}' 2>/dev/null | awk -v s="$session" '$1==s {print $2" "$3}' || true)
  if [[ -n "$all_panes" ]]; then
    while IFS= read -r pane_id dead_flag; do
      [[ -z "$pane_id" ]] && continue
      if [[ "$dead_flag" == "1" ]]; then
        tmux kill-pane -t "$pane_id" >/dev/null 2>&1 || true
        _tmux_remove_pane_id_by_pane_id "$session" "$pane_id"
        _tmux_remove_group_worker_by_pane_id "$session" "$pane_id"
      fi
    done <<< "$all_panes"
  fi

  local pane_ids
  pane_ids=$(_tmux_get_all_pane_ids "$session")
  if [[ -z "$pane_ids" ]]; then
    return 0
  fi

  while IFS= read -r pane_id; do
    [[ -z "$pane_id" ]] && continue

    local dead_flag=""
    if dead_flag=$(tmux display-message -p -t "$pane_id" '#{pane_dead}' 2>/dev/null); then
      if [[ "$dead_flag" == "1" ]]; then
        tmux kill-pane -t "$pane_id" >/dev/null 2>&1 || true
        _tmux_remove_pane_id_by_pane_id "$session" "$pane_id"
        _tmux_remove_group_worker_by_pane_id "$session" "$pane_id"
      fi
    else
      # Pane no longer exists; clean up tracking
      _tmux_remove_pane_id_by_pane_id "$session" "$pane_id"
      _tmux_remove_group_worker_by_pane_id "$session" "$pane_id"
    fi
  done <<< "$pane_ids"
}

# Ensure a sub-manager pane exists for a group (returns pane id)
tmux_ensure_group_pane() {
  local session="$1"
  local group="$2"

  if _tmux_group_exists "$session" "$group"; then
    local sub_pane window_id
    window_id=$(_tmux_get_group_window "$session" "$group")
    sub_pane=$(_tmux_get_group_sub_pane "$session" "$group")
    if [[ -n "$window_id" ]] && tmux display-message -p -t "$window_id" '#{window_id}' >/dev/null 2>&1; then
      if [[ -n "$sub_pane" ]] && tmux display-message -p -t "$sub_pane" '#{pane_id}' >/dev/null 2>&1; then
        printf "%s" "$sub_pane"
        return 0
      fi
    fi
  fi

  local window_name="group-${group}"
  local window_id
  window_id=$(tmux new-window -d -t "$session" -n "$window_name" -P -F '#{window_id}' "bash")
  if [[ -z "$window_id" ]]; then
    printf "%s" ""
    return 0
  fi

  local sub_pane=""
  sub_pane=$(tmux list-panes -t "$window_id" -F '#{pane_id}' | head -n 1)

  if [[ -n "$sub_pane" ]]; then
    tmux select-pane -t "$sub_pane" -T "Sub manager: $group" >/dev/null 2>&1 || true
    tmux send-keys -t "$sub_pane" "printf 'Sub manager / ${group} work\\n'" C-m >/dev/null 2>&1 || true
    _tmux_set_group_info "$session" "$group" "$window_id" "$sub_pane"
  fi

  printf "%s" "$sub_pane"
  return 0
}

# Create a worker pane for a step
# Sets TMUX_LAST_PANE_ID to the new pane's ID
# $4 (optional): Title for the pane (e.g., "Step 3: Architect")
TMUX_LAST_PANE_ID=""
tmux_create_worker_pane() {
  local session="$1"
  local step_num="$2"
  local command="$3"
  local title="${4:-Step $step_num}"
  local group="${5:-}"

  # Clean up dead panes before creating new ones
  tmux_cleanup_dead_worker_panes "$session"

  if [[ -z "$group" ]]; then
    local existing_groups
    existing_groups=$(_tmux_get_group_names "$session")
    if [[ -n "$existing_groups" ]]; then
      group="serial"
    fi
  fi

  local worker_count
  worker_count=$(_tmux_get_worker_count "$session")
  local pane_id

  # Wrap command with header display
  local wrapped_command="printf '\\n\\033[1;36m═══════════════════════════════════════\\033[0m\\n'; printf '\\033[1;37m  $title\\033[0m\\n'; printf '\\033[1;36m═══════════════════════════════════════\\033[0m\\n\\n'; $command"

  if [[ -n "$group" ]]; then
    # Grouped layout: create sub-manager + workers within group window
    local sub_pane
    sub_pane=$(tmux_ensure_group_pane "$session" "$group")
    if [[ -z "$sub_pane" ]]; then
      # Fallback to non-group layout if group pane can't be created
      group=""
    fi
  fi

  if [[ -n "$group" ]]; then
    local group_worker_count
    group_worker_count=$(_tmux_get_group_worker_count "$session" "$group")

    if [[ "$group_worker_count" -eq 0 ]]; then
      # First worker in group: split sub-manager vertically to create worker pane
      local sub_pane
      sub_pane=$(_tmux_get_group_sub_pane "$session" "$group")
      pane_id=$(tmux split-window -v -t "$sub_pane" -p 75 -P -F '#{pane_id}' "$wrapped_command")
      if [[ -z "$pane_id" ]]; then
        tmux_rebalance_group_window "$session" "$group" "4"
        pane_id=$(tmux split-window -v -t "$sub_pane" -p 75 -P -F '#{pane_id}' "$wrapped_command")
      fi
    else
      # Additional workers: split last worker horizontally within group
      local last_pane
      last_pane=$(_tmux_get_last_group_worker_pane "$session" "$group")
      if [[ -n "$last_pane" ]]; then
        pane_id=$(tmux split-window -h -t "$last_pane" -P -F '#{pane_id}' "$wrapped_command")
        if [[ -z "$pane_id" ]]; then
          tmux_rebalance_group_window "$session" "$group" "4"
          pane_id=$(tmux split-window -h -t "$last_pane" -P -F '#{pane_id}' "$wrapped_command")
        fi
      fi
    fi

    if [[ -z "$pane_id" ]]; then
      # Final fallback: put the worker in its own window to avoid failing the step
      local overflow_name="group-${group}-step-${step_num}"
      local overflow_window
      overflow_window=$(tmux new-window -d -t "$session" -n "$overflow_name" -P -F '#{window_id}' "$wrapped_command")
      if [[ -n "$overflow_window" ]]; then
        pane_id=$(tmux list-panes -t "$overflow_window" -F '#{pane_id}' | head -n 1)
      fi
    fi

    if [[ -n "$pane_id" ]]; then
      _tmux_add_group_worker "$session" "$step_num" "$group" "$pane_id"
    fi
  else
    if [[ "$worker_count" -eq 0 ]]; then
      # First worker: split control pane vertically (control top 30%, worker bottom 70%)
      pane_id=$(tmux split-window -v -t "${session}:0.0" -p 70 -P -F '#{pane_id}' "$wrapped_command")
    else
      # Additional workers: split the last worker pane horizontally
      local last_pane
      last_pane=$(_tmux_get_all_pane_ids "$session" | tail -1)

      if [[ -n "$last_pane" ]]; then
        # Split horizontally (side by side)
        pane_id=$(tmux split-window -h -t "$last_pane" -P -F '#{pane_id}' "$wrapped_command")
      else
        # Fallback: split from control pane
        pane_id=$(tmux split-window -v -t "${session}:0.0" -p 70 -P -F '#{pane_id}' "$wrapped_command")
      fi
    fi
  fi

  # Rebalance layout after adding new pane
  if [[ -n "$group" ]]; then
    tmux_rebalance_group_window "$session" "$group"
  else
    tmux_rebalance_layout "$session"
  fi

  if [[ -n "$pane_id" ]]; then
    # Set pane title (visible in status bar and when hovering)
    tmux select-pane -t "$pane_id" -T "$title" >/dev/null 2>&1 || true

    _tmux_set_pane_id "$session" "$step_num" "$pane_id"
    TMUX_LAST_PANE_ID="$pane_id"
  else
    TMUX_LAST_PANE_ID=""
  fi
}

# Remove a worker pane when step completes
tmux_remove_worker_pane() {
  local session="$1"
  local step_num="$2"

  local pane_id
  pane_id=$(_tmux_get_pane_id "$session" "$step_num")
  local group
  group=$(_tmux_get_group_for_step "$session" "$step_num")

  if [[ -n "$pane_id" ]]; then
    tmux kill-pane -t "$pane_id" >/dev/null 2>&1 || true
    _tmux_remove_pane_id "$session" "$step_num"
    if [[ -n "$group" ]]; then
      _tmux_remove_group_worker_by_step "$session" "$step_num"
      tmux_rebalance_group_window "$session" "$group"
    fi

    # Rebalance remaining panes
    local remaining
    remaining=$(_tmux_get_worker_count "$session")
    if [[ -z "$group" && "$remaining" -gt 0 ]]; then
      tmux_rebalance_layout "$session"
    fi
  fi
}

# Rebalance a group window: keep sub-manager height consistent
tmux_rebalance_group_window() {
  local session="$1"
  local group="$2"
  local sub_height="${3:-6}"

  if [[ "$sub_height" -lt 4 ]]; then
    sub_height=4
  fi

  local window_id
  window_id=$(_tmux_get_group_window "$session" "$group")
  local sub_pane
  sub_pane=$(_tmux_get_group_sub_pane "$session" "$group")

  if [[ -n "$window_id" && -n "$sub_pane" ]]; then
    tmux resize-pane -t "$sub_pane" -y "$sub_height" >/dev/null 2>&1 || true
  fi
}

# Rebalance layout: control on top, workers evenly split on bottom
tmux_rebalance_layout() {
  local session="$1"

  # Clean up dead panes before recalculating layout
  tmux_cleanup_dead_worker_panes "$session"

  local pane_ids
  pane_ids=$(_tmux_get_non_group_worker_panes "$session")
  local worker_count=0
  if [[ -n "$pane_ids" ]]; then
    worker_count=$(printf "%s" "$pane_ids" | wc -l | tr -d ' ')
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

  if [[ "$worker_count" -eq 0 ]]; then
    return 0
  fi

  # Enforce main-horizontal layout for non-group workers
  tmux select-pane -t "${session}:0.0" >/dev/null 2>&1 || true
  tmux select-layout -t "${session}:0" main-horizontal >/dev/null 2>&1 || true

  # Evenly distribute worker panes horizontally
  local worker_width=$((win_width / worker_count))
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
  rm -f "$(_tmux_group_file "$session")" 2>/dev/null || true
  rm -f "$(_tmux_group_workers_file "$session")" 2>/dev/null || true
}
