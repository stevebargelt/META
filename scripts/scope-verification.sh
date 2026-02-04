#!/usr/bin/env bash
set -euo pipefail

# Scope Verification Gate
# Compares PRD requirements against generated pipeline to catch silent scope reductions.
# Exit 0 = all PRD items covered, exit 1 = gaps found without approved deferrals.
#
# Checks:
#  1. Platforms in PRD (web, mobile, desktop, CLI) have implementation steps
#  2. Must-Have features in PRD have implementation steps
#  3. Gaps are either covered in pipeline OR explicitly deferred in docs/DEFERRED.md
#
# Usage: scope-verification.sh --project <path>

usage() {
  echo "Usage: scope-verification.sh --project <path>"
  echo ""
  echo "Compares PRD requirements against generated pipeline."
  echo "Fails if any PRD item is missing from pipeline without explicit deferral."
}

PROJECT=""
VERBOSE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project) PROJECT="$2"; shift 2 ;;
    --verbose|-v) VERBOSE=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ -z "$PROJECT" ]]; then
  echo "Error: --project is required" >&2
  usage
  exit 1
fi

if [[ ! -d "$PROJECT" ]]; then
  echo "Error: project directory not found: $PROJECT" >&2
  exit 1
fi

cd "$PROJECT"

# Check required files exist
PRD_FILE=""
for prd in docs/PRD.md docs/PRD-*.md PRD.md; do
  if [[ -f "$prd" ]]; then
    PRD_FILE="$prd"
    break
  fi
done

if [[ -z "$PRD_FILE" ]]; then
  echo "Error: No PRD file found (docs/PRD.md or docs/PRD-*.md)" >&2
  exit 1
fi

PIPELINE_FILE=""
for pipeline in .meta/next.pipeline .meta/composed.pipeline; do
  if [[ -f "$pipeline" ]]; then
    PIPELINE_FILE="$pipeline"
    break
  fi
done

if [[ -z "$PIPELINE_FILE" ]]; then
  echo "Error: No pipeline file found (.meta/next.pipeline or .meta/composed.pipeline)" >&2
  exit 1
fi

DEFERRED_FILE="docs/DEFERRED.md"

echo "Scope Verification Gate"
echo "─────────────────────────────────"
echo "PRD:      $PRD_FILE"
echo "Pipeline: $PIPELINE_FILE"
if [[ -f "$DEFERRED_FILE" ]]; then
  echo "Deferred: $DEFERRED_FILE"
fi
echo ""

GAPS=()
COVERED=()
DEFERRED=()

# Helper: Check if pipeline mentions a term (case-insensitive)
pipeline_covers() {
  local term="$1"
  grep -qi "$term" "$PIPELINE_FILE" 2>/dev/null
}

# Helper: Check if deferred file mentions a term (case-insensitive)
is_deferred() {
  local term="$1"
  if [[ -f "$DEFERRED_FILE" ]]; then
    grep -qi "$term" "$DEFERRED_FILE" 2>/dev/null
  else
    return 1
  fi
}

# Extract platforms from PRD
# Look for common platform indicators
extract_platforms() {
  local platforms=()

  # Web indicators
  if grep -qiE "web app|web application|react app|next\.js|vue|angular|browser|website" "$PRD_FILE"; then
    platforms+=("web")
  fi

  # Mobile indicators
  if grep -qiE "mobile app|ios|android|react native|expo|flutter|native app" "$PRD_FILE"; then
    platforms+=("mobile")
  fi

  # Desktop indicators
  if grep -qiE "desktop app|electron|tauri|macos app|windows app" "$PRD_FILE"; then
    platforms+=("desktop")
  fi

  # CLI indicators
  if grep -qiE "cli|command.line|terminal app" "$PRD_FILE"; then
    platforms+=("cli")
  fi

  echo "${platforms[@]}"
}

# Extract Must-Have features from PRD
# Look for sections like "Must Have", "MVP", "Required", "P0"
extract_must_haves() {
  local in_must_have=false
  local features=()

  while IFS= read -r line; do
    # Detect must-have section headers
    if echo "$line" | grep -qiE "^#+.*must.have|^#+.*mvp|^#+.*required|^#+.*p0|^#+.*core features"; then
      in_must_have=true
      continue
    fi

    # Detect end of section (new header)
    if [[ "$in_must_have" == true ]] && echo "$line" | grep -qE "^#+"; then
      in_must_have=false
    fi

    # Extract feature items (lines starting with - or *)
    if [[ "$in_must_have" == true ]] && echo "$line" | grep -qE "^[[:space:]]*[-*]"; then
      # Clean up the line: remove leading -, *, whitespace
      feature=$(echo "$line" | sed 's/^[[:space:]]*[-*][[:space:]]*//' | sed 's/[[:space:]]*$//')
      if [[ -n "$feature" && ${#feature} -gt 3 ]]; then
        features+=("$feature")
      fi
    fi
  done < "$PRD_FILE"

  printf '%s\n' "${features[@]}"
}

# Check platforms
echo "Checking platforms..."
platforms=($(extract_platforms))

if [[ ${#platforms[@]} -eq 0 ]]; then
  echo "  ⚠ No platforms detected in PRD (check PRD format)"
else
  for platform in "${platforms[@]}"; do
    if pipeline_covers "$platform"; then
      COVERED+=("Platform: $platform")
      echo "  ✓ $platform — covered in pipeline"
    elif is_deferred "$platform"; then
      DEFERRED+=("Platform: $platform")
      echo "  ⊘ $platform — explicitly deferred"
    else
      GAPS+=("Platform: $platform")
      echo "  ✗ $platform — NOT in pipeline, NOT deferred"
    fi
  done
fi

echo ""
echo "Checking Must-Have features..."

# Read features into array
mapfile -t must_haves < <(extract_must_haves)

if [[ ${#must_haves[@]} -eq 0 ]]; then
  echo "  ⚠ No Must-Have features detected (check PRD format)"
  echo "    Expected: Section with 'Must Have', 'MVP', 'Required', or 'P0' header"
else
  for feature in "${must_haves[@]}"; do
    # Create search terms from the feature (first few significant words)
    search_term=$(echo "$feature" | cut -d' ' -f1-4 | tr '[:upper:]' '[:lower:]')

    # Also try the first word as a keyword
    keyword=$(echo "$feature" | awk '{print $1}' | tr '[:upper:]' '[:lower:]')

    if pipeline_covers "$search_term" || pipeline_covers "$keyword"; then
      COVERED+=("Feature: $feature")
      if [[ "$VERBOSE" == true ]]; then
        echo "  ✓ $feature"
      fi
    elif is_deferred "$search_term" || is_deferred "$keyword"; then
      DEFERRED+=("Feature: $feature")
      echo "  ⊘ $feature — deferred"
    else
      # For features, we do a more lenient check - look for any key noun
      # Extract nouns (capitalized words, common tech terms)
      found=false
      for word in $(echo "$feature" | grep -oE '\b[A-Z][a-z]+\b|\b(auth|api|data|sync|user|task|event|calendar|meal|recipe)\b' | head -3); do
        if pipeline_covers "$word"; then
          found=true
          break
        fi
      done

      if [[ "$found" == true ]]; then
        COVERED+=("Feature: $feature")
        if [[ "$VERBOSE" == true ]]; then
          echo "  ✓ $feature"
        fi
      else
        GAPS+=("Feature: $feature")
        echo "  ✗ $feature — NOT in pipeline"
      fi
    fi
  done

  if [[ "$VERBOSE" != true ]]; then
    covered_count=$((${#must_haves[@]} - ${#GAPS[@]} - ${#DEFERRED[@]}))
    if [[ $covered_count -gt 0 ]]; then
      echo "  ✓ $covered_count features covered (use --verbose to list)"
    fi
  fi
fi

echo ""
echo "─────────────────────────────────"
echo "Summary"
echo "─────────────────────────────────"
echo "  Covered:  ${#COVERED[@]}"
echo "  Deferred: ${#DEFERRED[@]}"
echo "  Gaps:     ${#GAPS[@]}"

if [[ ${#GAPS[@]} -gt 0 ]]; then
  echo ""
  echo "⚠ SCOPE VERIFICATION FAILED"
  echo ""
  echo "The following PRD items are NOT covered in the pipeline:"
  for gap in "${GAPS[@]}"; do
    echo "  • $gap"
  done
  echo ""
  echo "To proceed, either:"
  echo "  1. Add implementation steps to the pipeline for these items"
  echo "  2. Create docs/DEFERRED.md with explicit deferrals and justifications"
  echo ""
  echo "Example docs/DEFERRED.md format:"
  echo "  # Deferred Items"
  echo "  "
  echo "  ## Mobile App"
  echo "  - **What:** iOS and Android React Native apps"
  echo "  - **Why:** Focusing on web MVP first"
  echo "  - **When:** Phase 2 (after web launch)"
  echo "  - **Approved:** 2026-02-03"
  exit 1
fi

echo ""
echo "✓ Scope verification passed"
exit 0
