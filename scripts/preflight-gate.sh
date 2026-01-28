#!/usr/bin/env bash
set -euo pipefail

# Pre-implementation verification checks.
# Run BEFORE starting implementation to catch blockers early.
# Replaces LLM-driven preflight-checklist.md with actual verification.
# Exit 0 = ready to start, exit 1 = blockers found.
#
# Checks performed:
#  1. Required tools available (node, npm, git)
#  2. Optional tools available (docker, supabase) - warn only
#  3. Project config exists (AGENTS.md or CLAUDE.md)
#  4. Dependencies installed (node_modules)
#  5. Environment file exists (.env or .env.local)
#  6. Environment variables documented (.env.example)
#  7. Required env vars present (compare .env to .env.example)

usage() {
  echo "Usage: preflight-gate.sh --project <path>"
  echo ""
  echo "Options:"
  echo "  --project <path>  Path to project directory (required)"
  echo "  --strict          Treat warnings as failures"
  echo "  -h, --help        Show this help message"
}

PROJECT=""
STRICT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project) PROJECT="$2"; shift 2 ;;
    --strict) STRICT=true; shift ;;
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
WARN=0

result() {
  local status="$1" name="$2" detail="${3:-}"
  case "$status" in
    pass) ((PASS++)); printf "  ✓ %s" "$name" ;;
    fail) ((FAIL++)); printf "  ✗ %s" "$name" ;;
    warn)
      ((WARN++))
      if [[ "$STRICT" == "true" ]]; then
        ((FAIL++))
        printf "  ✗ %s" "$name"
      else
        printf "  ⚠ %s" "$name"
      fi
      ;;
  esac
  if [[ -n "$detail" ]]; then
    printf " — %s" "$detail"
  fi
  printf "\n"
}

echo "Preflight Check: $PROJECT"
echo "─────────────────────────────────"

# 1. Required tools
echo ""
echo "Required Tools:"
for cmd in node npm git; do
  if command -v "$cmd" >/dev/null 2>&1; then
    version=$("$cmd" --version 2>/dev/null | head -1)
    result pass "$cmd" "$version"
  else
    result fail "$cmd" "not found in PATH"
  fi
done

# 2. Optional tools (warn only)
echo ""
echo "Optional Tools:"

# Check for Supabase indicators
uses_supabase=false
if [[ -d "supabase" ]] || grep -q "SUPABASE" .env.example 2>/dev/null || grep -q "supabase" package.json 2>/dev/null; then
  uses_supabase=true
fi

# Check for Docker indicators
uses_docker=false
if [[ -f "Dockerfile" ]] || [[ -f "docker-compose.yml" ]] || [[ -f "docker-compose.yaml" ]]; then
  uses_docker=true
fi

if [[ "$uses_supabase" == "true" ]]; then
  if command -v supabase >/dev/null 2>&1; then
    version=$(supabase --version 2>/dev/null | head -1)
    result pass "supabase" "$version"
  else
    result warn "supabase" "CLI not found (project appears to use Supabase)"
  fi
else
  result pass "supabase" "not needed"
fi

if [[ "$uses_docker" == "true" ]] || [[ "$uses_supabase" == "true" ]]; then
  if command -v docker >/dev/null 2>&1; then
    if docker info >/dev/null 2>&1; then
      result pass "docker" "running"
    else
      result warn "docker" "installed but not running"
    fi
  else
    result warn "docker" "not found (project may need it)"
  fi
else
  result pass "docker" "not needed"
fi

# 3. Project config
echo ""
echo "Project Config:"
if [[ -f "AGENTS.md" ]]; then
  result pass "Agent config" "AGENTS.md"
elif [[ -f "CLAUDE.md" ]]; then
  result pass "Agent config" "CLAUDE.md"
else
  result warn "Agent config" "no AGENTS.md or CLAUDE.md found"
fi

if [[ -f "README.md" ]]; then
  result pass "README.md" "exists"
else
  result warn "README.md" "missing"
fi

# 4. Dependencies
echo ""
echo "Dependencies:"
if [[ -f "package.json" ]]; then
  if [[ -d "node_modules" ]]; then
    result pass "node_modules" "installed"
  else
    result warn "node_modules" "missing — run: npm install"
  fi
else
  # Check monorepo structure
  found_pkg=false
  for subdir in server client backend frontend; do
    if [[ -f "$subdir/package.json" ]]; then
      found_pkg=true
      if [[ -d "$subdir/node_modules" ]]; then
        result pass "node_modules ($subdir)" "installed"
      else
        result warn "node_modules ($subdir)" "missing — run: npm install"
      fi
    fi
  done
  if [[ "$found_pkg" == "false" ]]; then
    result pass "node_modules" "no package.json found"
  fi
fi

# 5. Environment file
echo ""
echo "Environment:"
if [[ -f ".env" ]]; then
  result pass ".env" "exists"
  env_file=".env"
elif [[ -f ".env.local" ]]; then
  result pass ".env.local" "exists"
  env_file=".env.local"
else
  result warn ".env" "missing — copy from .env.example"
  env_file=""
fi

# 6. Environment documentation
if [[ -f ".env.example" ]]; then
  result pass ".env.example" "exists"

  # 7. Check required env vars are present
  if [[ -n "$env_file" ]]; then
    missing_vars=()
    while IFS='=' read -r key value || [[ -n "$key" ]]; do
      # Skip comments and empty lines
      [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
      # Extract just the key name (before =)
      key=$(echo "$key" | sed 's/[[:space:]]*=.*//' | tr -d '[:space:]')
      [[ -z "$key" ]] && continue

      # Check if this key exists in the env file
      if ! grep -q "^${key}=" "$env_file" 2>/dev/null; then
        missing_vars+=("$key")
      fi
    done < .env.example

    if [[ ${#missing_vars[@]} -eq 0 ]]; then
      result pass "Env vars" "all documented vars present in $env_file"
    else
      # Show first 3 missing vars
      missing_display="${missing_vars[*]:0:3}"
      if [[ ${#missing_vars[@]} -gt 3 ]]; then
        missing_display="$missing_display (+$((${#missing_vars[@]} - 3)) more)"
      fi
      result warn "Env vars" "missing: $missing_display"
    fi
  fi
else
  result warn ".env.example" "missing — env vars not documented"
fi

# Summary
echo ""
echo "─────────────────────────────────"
if [[ "$STRICT" == "true" ]]; then
  echo "Results: $PASS passed, $FAIL failed (strict mode, warnings = failures)"
else
  echo "Results: $PASS passed, $FAIL failed, $WARN warnings"
fi

if [[ "$FAIL" -gt 0 ]]; then
  echo ""
  echo "❌ Preflight failed — resolve blockers before starting implementation"
  exit 1
elif [[ "$WARN" -gt 0 ]] && [[ "$STRICT" == "false" ]]; then
  echo ""
  echo "⚠️  Preflight passed with warnings — consider resolving before starting"
  exit 0
else
  echo ""
  echo "✅ Preflight passed — ready to start implementation"
  exit 0
fi
