#!/usr/bin/env bash
set -euo pipefail

session="${1:-}"
lines="${2:-6}"
max_panes="${3:-4}"

if [[ -z "$session" ]]; then
  exit 0
fi

if ! command -v tmux >/dev/null 2>&1; then
  exit 0
fi

if ! tmux has-session -t "$session" 2>/dev/null; then
  exit 0
fi

pane_file="/tmp/meta-panes-${session}.txt"

step_for_pane() {
  local pane_id="$1"
  if [[ -f "$pane_file" ]]; then
    grep -E "^[0-9]+:${pane_id}$" "$pane_file" 2>/dev/null | head -n 1 | cut -d: -f1
  fi
}

panes=$(tmux list-panes -t "${session}:0" -F '#{pane_id} #{pane_active} #{pane_title}' 2>/dev/null || true)
if [[ -z "$panes" ]]; then
  exit 0
fi

echo "Tmux snapshot (${session})"
echo "------------------------"

count=0
while IFS= read -r pane_id pane_active pane_title; do
  [[ -z "$pane_id" ]] && continue
  count=$((count + 1))
  if [[ "$count" -gt "$max_panes" ]]; then
    break
  fi

  step=""
  step=$(step_for_pane "$pane_id" || true)

  label="Pane ${pane_id}"
  if [[ -n "$step" ]]; then
    label="Step ${step}"
  fi
  if [[ "$pane_active" == "1" ]]; then
    label="${label} (active)"
  fi
  if [[ -n "$pane_title" ]]; then
    label="${label} — ${pane_title}"
  fi

  echo "$label:"
  tmux capture-pane -t "$pane_id" -p -S "-${lines}" 2>/dev/null | sed 's/^/  | /'
  echo ""

done <<< "$panes"
