#!/usr/bin/env bash
set -euo pipefail

# Machine-verifiable quality gate checks.
# Replaces LLM-driven validation steps with actual verification.
# Exit 0 = all checks pass, exit 1 = at least one check failed.
#
# Checks performed:
#  1. Git commits exist
#  2. README.md exists and is non-empty
#  3. .gitignore exists
#  4. .env.example exists (documents required env vars)
#  5. CI workflow exists (.github/workflows, .gitlab-ci, .circleci)
#  6. Tests pass (npm test, supports monorepo)
# 6a. Test coverage meets threshold (60% default, if coverage data exists)
# 6b. No .only() in tests (prevents committed focused tests)
#  7. TypeScript compiles (tsc --noEmit)
#  8. Lint passes (npm run lint or eslint)
#  9. OpenAPI valid (redocly lint if docs/openapi.yaml exists)
# 10. Observability (correlation ID references in server code)
# 11. No mock data in production code (detects mockData patterns)
# 12. CD workflow exists (deployment, not just CI)
# 13. Client-side observability (Sentry + PostHog in frontend)
# 14. Placeholder page detection ("Coming soon", etc.)
# 15. Stub/TODO detection in production code
# 16. DEFERRED.md check (flag for review if exists)
# 17. Build succeeds (npm run build)

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

# 4. .env.example exists (documents required env vars)
if [[ -f .env.example ]] && [[ -s .env.example ]]; then
  result pass ".env.example" "exists"
else
  result fail ".env.example" "missing — env vars not documented"
fi

# 5. CI workflow exists
ci_workflow=""
for pattern in .github/workflows/*.yml .github/workflows/*.yaml .gitlab-ci.yml .circleci/config.yml; do
  if ls $pattern 2>/dev/null | head -1 >/dev/null; then
    ci_workflow=$(ls $pattern 2>/dev/null | head -1)
    break
  fi
done
if [[ -n "$ci_workflow" ]]; then
  result pass "CI workflow" "$ci_workflow"
else
  result fail "CI workflow" "no CI config found (.github/workflows/, .gitlab-ci.yml, .circleci/)"
fi

# 6. Tests pass (if package.json has a test script)
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

# 6a. Test coverage threshold (optional, if coverage configured)
# Looks for coverage summary in common locations and checks threshold
COVERAGE_THRESHOLD=60

check_coverage_in_dir() {
  local dir="$1"
  local summary_file=""

  # Look for coverage summary in common locations
  for path in "coverage/coverage-summary.json" "coverage/coverage-final.json" ".nyc_output/coverage-summary.json"; do
    if [[ -f "$dir/$path" ]]; then
      summary_file="$dir/$path"
      break
    fi
  done

  if [[ -z "$summary_file" ]]; then
    echo "skip:no coverage data"
    return
  fi

  # Try to extract line coverage percentage
  if command -v jq >/dev/null 2>&1; then
    local coverage
    coverage=$(jq -r '.total.lines.pct // .total.statements.pct // empty' "$summary_file" 2>/dev/null)
    if [[ -n "$coverage" ]] && [[ "$coverage" != "null" ]]; then
      # Compare coverage to threshold (using awk for float comparison)
      if awk "BEGIN {exit !($coverage >= $COVERAGE_THRESHOLD)}"; then
        echo "pass:${coverage}%"
      else
        echo "fail:${coverage}% < ${COVERAGE_THRESHOLD}%"
      fi
    else
      echo "skip:could not parse coverage"
    fi
  else
    echo "skip:jq not installed"
  fi
}

# Only check coverage if tests passed
if [[ "$test_results" == "root_pass" ]]; then
  coverage_result=$(check_coverage_in_dir ".")
  case "$coverage_result" in
    pass:*) result pass "Coverage" "${coverage_result#pass:}" ;;
    fail:*) result fail "Coverage" "${coverage_result#fail:}" ;;
    skip:*) result skip "Coverage" "${coverage_result#skip:}" ;;
  esac
elif [[ "$test_results" == "check_monorepo" ]] && [[ ${#monorepo_dirs[@]} -gt 0 ]]; then
  coverage_checked=false
  for subdir in "${monorepo_dirs[@]}"; do
    coverage_result=$(check_coverage_in_dir "$subdir")
    case "$coverage_result" in
      pass:*)
        result pass "Coverage ($subdir)" "${coverage_result#pass:}"
        coverage_checked=true
        ;;
      fail:*)
        result fail "Coverage ($subdir)" "${coverage_result#fail:}"
        coverage_checked=true
        ;;
    esac
  done
  if [[ "$coverage_checked" == "false" ]]; then
    result skip "Coverage" "no coverage data in monorepo subdirs"
  fi
else
  result skip "Coverage" "tests did not pass"
fi

# 6b. No .only() in tests (prevents accidentally committed focused tests)
test_dirs=""
for d in test tests __tests__ src; do
  [[ -d "$d" ]] && test_dirs="$test_dirs $d"
done
# Also check monorepo subdirs
for subdir in server client backend frontend; do
  for d in "$subdir/test" "$subdir/tests" "$subdir/__tests__" "$subdir/src"; do
    [[ -d "$d" ]] && test_dirs="$test_dirs $d"
  done
done

if [[ -n "$test_dirs" ]]; then
  # Look for .only( in test files (disable pipefail temporarily)
  only_files=$(set +o pipefail; grep -rl "\.only(" $test_dirs --include="*.test.*" --include="*.spec.*" 2>/dev/null | wc -l | tr -d ' ')
  only_files=${only_files:-0}
  if [[ "$only_files" -gt 0 ]]; then
    result fail "Focused tests" ".only() found in $only_files file(s)"
  else
    result pass "Focused tests" "no .only() calls found"
  fi
else
  result skip "Focused tests" "no test directories found"
fi

# 7. TypeScript compiles (if tsconfig.json exists)
tsconfig_found=""
for tsconfig in tsconfig.json server/tsconfig.json client/tsconfig.json; do
  [[ -f "$tsconfig" ]] && tsconfig_found="$tsconfig" && break
done
if [[ -n "$tsconfig_found" ]]; then
  tsconfig_dir=$(dirname "$tsconfig_found")
  if (cd "$tsconfig_dir" && npx tsc --noEmit 2>/dev/null); then
    result pass "TypeScript" "compiles without errors"
  else
    result fail "TypeScript" "type errors found (run: npx tsc --noEmit)"
  fi
else
  result skip "TypeScript" "no tsconfig.json found"
fi

# 8. Lint passes (if eslint config exists)
has_lint_script() {
  local pkg="$1"
  grep -q '"lint"[[:space:]]*:' "$pkg" 2>/dev/null
}

eslint_config=""
for config in .eslintrc .eslintrc.js .eslintrc.json .eslintrc.yml eslint.config.js eslint.config.mjs; do
  [[ -f "$config" ]] && eslint_config="$config" && break
done

if [[ -n "$eslint_config" ]] || has_lint_script "package.json"; then
  if [[ -f package.json ]] && has_lint_script "package.json"; then
    if npm run lint --silent 2>/dev/null; then
      result pass "Lint" "passed"
    else
      result fail "Lint" "lint errors found (run: npm run lint)"
    fi
  elif [[ -n "$eslint_config" ]]; then
    if npx eslint . --max-warnings 0 2>/dev/null; then
      result pass "Lint" "passed"
    else
      result fail "Lint" "lint errors found"
    fi
  fi
else
  result skip "Lint" "no eslint config or lint script"
fi

# 9. OpenAPI valid (if docs/openapi.yaml exists)
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

# 10. Observability (correlation ID in server code)
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

# 11. No mock data in production code
# Check for common mock data patterns in source files (excluding tests, stories, mocks)
src_dirs=""
for d in src app lib components pages; do
  [[ -d "$d" ]] && src_dirs="$src_dirs $d"
done
# Also check client/src, apps/web/src for monorepos
for d in client/src apps/web/src apps/mobile/src frontend/src; do
  [[ -d "$d" ]] && src_dirs="$src_dirs $d"
done

if [[ -n "$src_dirs" ]]; then
  # Look for mock data patterns, excluding test files, stories, and mock directories
  # Disable pipefail temporarily to handle grep returning 1 when nothing found
  mock_files=$(set +o pipefail; grep -rl "mockData\|mockTasks\|mockEvents\|mockMeals\|mockRecipes\|mockUsers\|const mock" $src_dirs \
    --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
    2>/dev/null | grep -v -E "\.test\.|\.spec\.|\.stories\.|__tests__|__mocks__|\.mock\." | wc -l | tr -d ' ')
  mock_files=${mock_files:-0}

  if [[ "$mock_files" -gt 0 ]]; then
    result fail "Mock data" "found mock data patterns in $mock_files production file(s)"
  else
    result pass "Mock data" "no mock data in production code"
  fi
else
  result skip "Mock data" "no source directories found"
fi

# 12. CD workflow exists (deployment, not just CI)
cd_workflow=""
# Check for deployment workflows
for pattern in .github/workflows/deploy*.yml .github/workflows/deploy*.yaml .github/workflows/cd*.yml .github/workflows/release*.yml; do
  if ls $pattern 2>/dev/null | head -1 >/dev/null; then
    cd_workflow=$(ls $pattern 2>/dev/null | head -1)
    break
  fi
done
# Also check for platform-specific auto-deploy configs
if [[ -z "$cd_workflow" ]]; then
  if [[ -f vercel.json ]]; then
    cd_workflow="vercel.json (auto-deploy)"
  elif [[ -f netlify.toml ]]; then
    cd_workflow="netlify.toml (auto-deploy)"
  elif [[ -f fly.toml ]]; then
    cd_workflow="fly.toml (auto-deploy)"
  fi
fi

if [[ -n "$cd_workflow" ]]; then
  result pass "CD workflow" "$cd_workflow"
else
  result fail "CD workflow" "no deployment workflow (CI is not CD)"
fi

# 13. Client-side observability (Sentry + PostHog in frontend)
web_pkg=""
for pkg in apps/web/package.json client/package.json frontend/package.json package.json; do
  if [[ -f "$pkg" ]]; then
    # Check if this is a web/frontend package (has react or vue)
    if grep -qE '"react"|"vue"|"@angular"' "$pkg" 2>/dev/null; then
      web_pkg="$pkg"
      break
    fi
  fi
done

if [[ -n "$web_pkg" ]]; then
  sentry_ok=""
  posthog_ok=""

  if grep -qE '"@sentry/react"|"@sentry/browser"|"@sentry/vue"|"@sentry/angular"' "$web_pkg" 2>/dev/null; then
    sentry_ok="yes"
  fi
  if grep -q '"posthog-js"' "$web_pkg" 2>/dev/null; then
    posthog_ok="yes"
  fi

  if [[ "$sentry_ok" == "yes" && "$posthog_ok" == "yes" ]]; then
    result pass "Client observability" "Sentry + PostHog in $web_pkg"
  elif [[ "$sentry_ok" == "yes" ]]; then
    result fail "Client observability" "Sentry found but PostHog missing in $web_pkg"
  elif [[ "$posthog_ok" == "yes" ]]; then
    result fail "Client observability" "PostHog found but Sentry missing in $web_pkg"
  else
    result fail "Client observability" "neither Sentry nor PostHog in $web_pkg"
  fi
else
  result skip "Client observability" "no frontend package.json found"
fi

# 13b. Client-side observability initialization (Sentry.init, posthog.init, ErrorBoundary)
frontend_dirs=""
for d in apps/web/src client/src frontend/src src app; do
  [[ -d "$d" ]] && frontend_dirs="$frontend_dirs $d"
done

if [[ -n "$web_pkg" && -n "$frontend_dirs" ]]; then
  if [[ "$sentry_ok" == "yes" && "$posthog_ok" == "yes" ]]; then
    # Disable pipefail temporarily to handle grep returning 1 when nothing found
    sentry_init_files=$(set +o pipefail; grep -rl "Sentry\\.init" $frontend_dirs \
      --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
      2>/dev/null | wc -l | tr -d ' ')
    posthog_init_files=$(set +o pipefail; grep -rl "posthog\\.init" $frontend_dirs \
      --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
      2>/dev/null | wc -l | tr -d ' ')
    error_boundary_files=$(set +o pipefail; grep -rlE "ErrorBoundary|Sentry\\.ErrorBoundary|Sentry\\.wrap" $frontend_dirs \
      --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
      2>/dev/null | wc -l | tr -d ' ')

    sentry_init_files=${sentry_init_files:-0}
    posthog_init_files=${posthog_init_files:-0}
    error_boundary_files=${error_boundary_files:-0}

    if [[ "$sentry_init_files" -gt 0 && "$posthog_init_files" -gt 0 && "$error_boundary_files" -gt 0 ]]; then
      result pass "Client observability init" "Sentry.init + posthog.init + ErrorBoundary found"
    else
      detail="missing:"
      [[ "$sentry_init_files" -eq 0 ]] && detail="$detail Sentry.init"
      [[ "$posthog_init_files" -eq 0 ]] && detail="$detail posthog.init"
      [[ "$error_boundary_files" -eq 0 ]] && detail="$detail ErrorBoundary"
      result fail "Client observability init" "$detail"
    fi
  else
    result skip "Client observability init" "client observability deps missing"
  fi
else
  result skip "Client observability init" "no frontend source directories found"
fi

# 14. Placeholder page detection
placeholder_dirs=""
for d in apps/web/src client/src frontend/src src pages components; do
  [[ -d "$d" ]] && placeholder_dirs="$placeholder_dirs $d"
done

if [[ -n "$placeholder_dirs" ]]; then
  # Disable pipefail temporarily to handle grep returning 1 when nothing found
  placeholder_files=$(set +o pipefail; grep -rl "Coming soon\|Placeholder\|Not yet implemented\|TODO: implement" $placeholder_dirs \
    --include="*.tsx" --include="*.jsx" --include="*.vue" \
    2>/dev/null | grep -v -E "\.test\.|\.spec\.|\.stories\." | wc -l | tr -d ' ')
  placeholder_files=${placeholder_files:-0}

  if [[ "$placeholder_files" -gt 0 ]]; then
    result fail "Placeholder pages" "$placeholder_files file(s) with placeholder content"
  else
    result pass "Placeholder pages" "no placeholder content found"
  fi
else
  result skip "Placeholder pages" "no frontend source directories found"
fi

# 15. Stub/TODO detection in production code
prod_dirs=""
for d in apps/web/src apps/mobile/src client/src server/src src lib; do
  [[ -d "$d" ]] && prod_dirs="$prod_dirs $d"
done

if [[ -n "$prod_dirs" ]]; then
  # Disable pipefail temporarily to handle grep returning 1 when nothing found
  stub_files=$(set +o pipefail; grep -rl 'throw.*not.*implement\|throw.*TODO\|// FIXME:.*critical\|# FIXME:.*critical' $prod_dirs \
    --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
    2>/dev/null | grep -v -E "\.test\.|\.spec\.|__tests__|__mocks__" | wc -l | tr -d ' ')
  stub_files=${stub_files:-0}

  if [[ "$stub_files" -gt 0 ]]; then
    result fail "Stubs in production" "$stub_files file(s) with unfinished stubs"
  else
    result pass "Stubs in production" "no critical stubs found"
  fi
else
  result skip "Stubs in production" "no production source directories found"
fi

# 16. DEFERRED.md check (flag for review if exists)
if [[ -f docs/DEFERRED.md ]]; then
  deferred_count=$(grep -cE "^##|^-" docs/DEFERRED.md 2>/dev/null || echo "0")
  result pass "Deferred items" "docs/DEFERRED.md exists ($deferred_count items) — verify approved"
else
  result skip "Deferred items" "no docs/DEFERRED.md (none deferred)"
fi

# 17. Build succeeds (if build script exists)
has_build_script() {
  local pkg="$1"
  grep -q '"build"[[:space:]]*:' "$pkg" 2>/dev/null
}

build_ran=false
if [[ -f package.json ]] && has_build_script "package.json"; then
  if npm run build --silent 2>/dev/null; then
    result pass "Build" "npm run build succeeded"
    build_ran=true
  else
    result fail "Build" "build failed (run: npm run build)"
    build_ran=true
  fi
fi

# Check monorepo subdirs if no root build
if [[ "$build_ran" == "false" ]]; then
  for subdir in server client backend frontend; do
    if [[ -f "$subdir/package.json" ]] && has_build_script "$subdir/package.json"; then
      if (cd "$subdir" && npm run build --silent 2>/dev/null); then
        result pass "Build ($subdir)" "succeeded"
      else
        result fail "Build ($subdir)" "failed"
      fi
      build_ran=true
    fi
  done
fi

if [[ "$build_ran" == "false" ]]; then
  result skip "Build" "no build script found"
fi

echo "─────────────────────────────────"
echo "Results: $PASS passed, $FAIL failed, $SKIP skipped"

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
