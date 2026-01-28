#!/usr/bin/env bash
set -euo pipefail

# Machine-verifiable quality gate checks.
# Replaces LLM-driven validation steps (observability, openapi, test-execution).
# Exit 0 = all checks pass, exit 1 = at least one check failed.

usage() {
  echo "Usage: quality-gate.sh --project <path>"
}

PROJECT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project) PROJECT="$2"; shift 2 ;;
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

PASS=0
FAIL=0
SKIP=0

result() {
  local status="$1" name="$2" detail="${3:-}"
  case "$status" in
    pass) ((PASS++)); printf "  ✓ %s" "$name" ;;
    fail) ((FAIL++)); printf "  ✗ %s" "$name" ;;
    skip) ((SKIP++)); printf "  - %s (skipped)" "$name" ;;
  esac
  if [[ -n "$detail" ]]; then
    printf " — %s" "$detail"
  fi
  printf "\n"
}

echo "Quality Gate: $PROJECT"
echo "─────────────────────────────────"

# 1. Git commits exist
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  commit_count=$(git log --oneline 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$commit_count" -gt 0 ]]; then
    result pass "Git commits" "$commit_count commit(s)"
  else
    result fail "Git commits" "no commits found"
  fi
else
  result skip "Git commits" "not a git repo"
fi

# 2. README.md exists and is non-empty
if [[ -f README.md ]] && [[ -s README.md ]]; then
  result pass "README.md" "exists, non-empty"
else
  result fail "README.md" "missing or empty"
fi

# 3. .gitignore exists
if [[ -f .gitignore ]] && [[ -s .gitignore ]]; then
  result pass ".gitignore" "exists"
else
  result fail ".gitignore" "missing — node_modules, .env, etc. may be committed"
fi

# 5. Tests pass (if package.json has a test script)
# Supports: root package.json, monorepo with server/client, or packages/*

has_test_script() {
  local pkg="$1"
  # Check if package.json has a "test" script that isn't the default "no test specified"
  if grep -q '"test"[[:space:]]*:' "$pkg" 2>/dev/null; then
    if grep -q 'no test specified' "$pkg" 2>/dev/null; then
      echo "no"
    else
      echo "yes"
    fi
  else
    echo "no"
  fi
}

run_tests_in_dir() {
  local dir="$1"
  local label="$2"
  if [[ -f "$dir/package.json" ]]; then
    local has_test
    has_test=$(has_test_script "$dir/package.json")
    if [[ "$has_test" == "yes" ]]; then
      if (cd "$dir" && npm test --silent >/dev/null 2>&1); then
        echo "pass:$label"
      else
        echo "fail:$label"
      fi
    else
      echo "skip:$label (no test script)"
    fi
  else
    echo "skip:$label (no package.json)"
  fi
}

test_results=""
test_locations=""

# Check root package.json first
if [[ -f package.json ]]; then
  has_test=$(has_test_script "./package.json")
  if [[ "$has_test" == "yes" ]]; then
    if npm test --silent 2>&1 >/dev/null; then
      result pass "Tests" "npm test passed (root)"
      test_results="root_pass"
    else
      result fail "Tests" "npm test failed (root)"
      test_results="root_fail"
    fi
  else
    # Root has package.json but no test script - check for monorepo
    test_results="check_monorepo"
  fi
else
  # No root package.json - check for monorepo structure
  test_results="check_monorepo"
fi

# If no root tests, check monorepo directories
if [[ "$test_results" == "check_monorepo" ]]; then
  monorepo_dirs=()
  for subdir in server client backend frontend api web; do
    if [[ -d "$subdir" ]] && [[ -f "$subdir/package.json" ]]; then
      monorepo_dirs+=("$subdir")
    fi
  done
  # Also check packages/* if it exists
  if [[ -d "packages" ]]; then
    for subdir in packages/*/; do
      if [[ -f "$subdir/package.json" ]]; then
        monorepo_dirs+=("${subdir%/}")
      fi
    done
  fi

  if [[ ${#monorepo_dirs[@]} -gt 0 ]]; then
    pass_count=0
    fail_count=0
    skip_count=0
    tested_dirs=""

    for subdir in "${monorepo_dirs[@]}"; do
      subdir_result=$(run_tests_in_dir "$subdir" "$subdir")
      case "$subdir_result" in
        pass:*) ((pass_count++)); tested_dirs="$tested_dirs ${subdir_result#pass:}" ;;
        fail:*) ((fail_count++)); tested_dirs="$tested_dirs ${subdir_result#fail:}" ;;
        skip:*) ((skip_count++)) ;;
      esac
    done

    if [[ $fail_count -gt 0 ]]; then
      result fail "Tests" "failed in:$tested_dirs"
    elif [[ $pass_count -gt 0 ]]; then
      result pass "Tests" "passed in:$tested_dirs"
    else
      result skip "Tests" "no test scripts in monorepo subdirs"
    fi
  else
    result skip "Tests" "no package.json at root or in subdirs"
  fi
fi

# 6. OpenAPI valid (if docs/openapi.yaml exists)
if [[ -f docs/openapi.yaml ]] || [[ -f docs/openapi.yml ]] || [[ -f docs/openapi.json ]]; then
  openapi_file=""
  for f in docs/openapi.yaml docs/openapi.yml docs/openapi.json; do
    [[ -f "$f" ]] && openapi_file="$f" && break
  done
  # Try npx redocly lint, fall back to file-exists check
  if command -v npx >/dev/null 2>&1 && npx redocly lint "$openapi_file" --skip-rule no-unused-components 2>&1 | grep -q "error"; then
    result fail "OpenAPI" "$openapi_file has validation errors"
  else
    result pass "OpenAPI" "$openapi_file present"
  fi
else
  result skip "OpenAPI" "no docs/openapi.yaml"
fi

# 7. Observability (correlation ID in server code)
server_dirs=""
for d in src server app lib; do
  [[ -d "$d" ]] && server_dirs="$server_dirs $d"
done
if [[ -n "$server_dirs" ]]; then
  if grep -rl "correlationId\|correlation_id\|X-Correlation-ID\|x-correlation-id\|traceparent" $server_dirs >/dev/null 2>&1; then
    result pass "Observability" "correlation ID references found"
  else
    result fail "Observability" "no correlation ID references in server code"
  fi
else
  result skip "Observability" "no server code directories found"
fi

echo "─────────────────────────────────"
echo "Results: $PASS passed, $FAIL failed, $SKIP skipped"

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
