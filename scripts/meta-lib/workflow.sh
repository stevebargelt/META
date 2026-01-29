#!/usr/bin/env bash

# Pipeline parsing utilities

WF_NAME=""
WF_DESCRIPTION=""
WF_TIMEOUT_MIN=60
WF_STEP_COUNT=0

declare -a WF_STEP_NUM
declare -a WF_STEP_AGENT
declare -a WF_STEP_CLI
declare -a WF_STEP_GATE
declare -a WF_STEP_GROUP
declare -a WF_STEP_TIMEOUT
declare -a WF_STEP_PROMPT

workflow_trim() {
  local value="$*"
  value="${value#${value%%[![:space:]]*}}"
  value="${value%${value##*[![:space:]]}}"
  printf "%s" "$value"
}

workflow_reset() {
  WF_NAME=""
  WF_DESCRIPTION=""
  WF_TIMEOUT_MIN=60
  WF_STEP_COUNT=0
  WF_STEP_NUM=()
  WF_STEP_AGENT=()
  WF_STEP_CLI=()
  WF_STEP_GATE=()
  WF_STEP_GROUP=()
  WF_STEP_TIMEOUT=()
  WF_STEP_PROMPT=()
}

workflow_parse() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    echo "Pipeline not found: $file" >&2
    return 1
  fi

  workflow_reset

  local line
  local line_no=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    line_no=$((line_no + 1))
    line="${line%$'\r'}"

    if [[ -z "${line//[[:space:]]/}" ]]; then
      continue
    fi
    if [[ "$line" =~ ^[[:space:]]*# ]]; then
      continue
    fi

    if [[ "$line" =~ ^[[:space:]]*name: ]]; then
      WF_NAME=$(workflow_trim "${line#*:}")
      continue
    fi

    if [[ "$line" =~ ^[[:space:]]*description: ]]; then
      WF_DESCRIPTION=$(workflow_trim "${line#*:}")
      continue
    fi

    if [[ "$line" =~ ^[[:space:]]*timeout_min: ]]; then
      local timeout_val
      timeout_val=$(workflow_trim "${line#*:}")
      if [[ -n "$timeout_val" ]]; then
        WF_TIMEOUT_MIN="$timeout_val"
      fi
      continue
    fi

    local safe
    safe="${line//\\|/$'\x1f'}"

    local f1 f2 f3 f4 f5 f6 f7
    IFS='|' read -r f1 f2 f3 f4 f5 f6 f7 <<< "$safe"

    f1=$(workflow_trim "${f1//$'\x1f'/|}")
    f2=$(workflow_trim "${f2//$'\x1f'/|}")
    f3=$(workflow_trim "${f3//$'\x1f'/|}")
    f4=$(workflow_trim "${f4//$'\x1f'/|}")
    f5=$(workflow_trim "${f5//$'\x1f'/|}")
    f6=$(workflow_trim "${f6//$'\x1f'/|}")
    f7=$(workflow_trim "${f7//$'\x1f'/|}")

    if [[ -z "$f1" || -z "$f2" || -z "$f3" || -z "$f4" || -z "$f7" ]]; then
      echo "Invalid pipeline line $line_no (expected 7 fields): $line" >&2
      return 1
    fi

    if [[ ! "$f1" =~ ^[0-9]+$ ]]; then
      echo "Invalid step number on line $line_no: $f1" >&2
      return 1
    fi

    WF_STEP_COUNT=$((WF_STEP_COUNT + 1))
    local idx="$WF_STEP_COUNT"

    if [[ "$f1" != "$idx" ]]; then
      echo "Step number mismatch on line $line_no: expected $idx, got $f1" >&2
      return 1
    fi

    if [[ "$f6" == "-" || -z "$f6" ]]; then
      f6="$WF_TIMEOUT_MIN"
    fi

    if [[ "$f5" == "-" ]]; then
      f5=""
    fi

    WF_STEP_NUM[$idx]="$f1"
    WF_STEP_AGENT[$idx]="$f2"
    WF_STEP_CLI[$idx]="$f3"
    WF_STEP_GATE[$idx]="$f4"
    WF_STEP_GROUP[$idx]="$f5"
    WF_STEP_TIMEOUT[$idx]="$f6"
    WF_STEP_PROMPT[$idx]="$f7"
  done < "$file"

  if [[ "$WF_STEP_COUNT" -eq 0 ]]; then
    echo "No steps found in pipeline: $file" >&2
    return 1
  fi

  return 0
}

# Inject a product-researcher step before the product-manager step
# Call after workflow_parse if --research flag is set
workflow_inject_research() {
  local insert_before=-1
  local idx

  # Find the first product-manager step
  for ((idx=1; idx<=WF_STEP_COUNT; idx++)); do
    if [[ "${WF_STEP_AGENT[$idx]}" == "product-manager" ]]; then
      insert_before=$idx
      break
    fi
  done

  if [[ "$insert_before" -eq -1 ]]; then
    echo "Note: --research specified but no product-manager step found; skipping research injection" >&2
    return 0
  fi

  # Shift all steps from insert_before onwards up by 1
  local new_count=$((WF_STEP_COUNT + 1))
  for ((idx=WF_STEP_COUNT; idx>=insert_before; idx--)); do
    local new_idx=$((idx + 1))
    WF_STEP_NUM[$new_idx]="$new_idx"
    WF_STEP_AGENT[$new_idx]="${WF_STEP_AGENT[$idx]}"
    WF_STEP_CLI[$new_idx]="${WF_STEP_CLI[$idx]}"
    WF_STEP_GATE[$new_idx]="${WF_STEP_GATE[$idx]}"
    WF_STEP_GROUP[$new_idx]="${WF_STEP_GROUP[$idx]}"
    WF_STEP_TIMEOUT[$new_idx]="${WF_STEP_TIMEOUT[$idx]}"
    WF_STEP_PROMPT[$new_idx]="${WF_STEP_PROMPT[$idx]}"
  done

  # Insert the research step
  WF_STEP_NUM[$insert_before]="$insert_before"
  WF_STEP_AGENT[$insert_before]="product-researcher"
  WF_STEP_CLI[$insert_before]="-"
  WF_STEP_GATE[$insert_before]="auto"
  WF_STEP_GROUP[$insert_before]=""
  WF_STEP_TIMEOUT[$insert_before]="30"
  WF_STEP_PROMPT[$insert_before]="Research competitors using META/agents/product-researcher.md. Read .meta/handoff.md for product context. Create docs/COMPETITIVE-ANALYSIS.md with feature matrix and recommendations. Update .meta/handoff.md with key findings."

  WF_STEP_COUNT=$new_count

  echo "Injected product-researcher step at position $insert_before (--research enabled)"
}
