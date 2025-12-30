#!/usr/bin/env bash
set -euo pipefail

# Verilog rules checker wrapper for Vcheck.class / VerFile.class
# Usage:
#   verilog_checker <assignment>       # runs recursively over all .v under assignments/<assignment>
#   verilog_checker <path>             # if file: only that .v; if dir: .v files in that dir (non-recursive)

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECKER_DIR="$REPO_ROOT/verilog_checker"
ASSIGNMENTS="hw01 hw02 hw03 hw04 hw05 hw06 lab project .testing"

if ! command -v java >/dev/null 2>&1; then
  echo "Error: java not found in PATH. Did you run inside the container via ./run?" >&2
  exit 1
fi

if [ $# -lt 1 ]; then
  echo "Usage: verilog_checker <assignment|path>" >&2
  exit 1
fi

target="$1"

run_file() {
  local f="$1"
  local base
  base="$(basename "$f")"
  if [[ "$base" == tb_* ]] || [[ "$base" == *_tb.v ]] || [[ "$base" == *tb.v ]]; then
    return 0
  fi
  echo "  [CHECK] $f"
  java -cp "$CHECKER_DIR" Vcheck "$f"
}

run_dir_recursive() {
  local dir="$1"
  local status=0
  local prev_dir=""
  while IFS= read -r f; do
    local d
    d="$(dirname "$f")"
    if [ "$d" != "$prev_dir" ]; then
      echo "== $d =="
      prev_dir="$d"
    fi
    if ! run_file "$f"; then
      status=1
    fi
  done < <(find "$dir" -type f -name '*.v' | sort)
  return $status
}

run_dir_non_recursive() {
  local dir="$1"
  local status=0
  for f in "$dir"/*.v; do
    [ -e "$f" ] || continue
    if ! run_file "$f"; then
      status=1
    fi
  done
  return $status
}

if echo "$ASSIGNMENTS" | tr ' ' '\n' | grep -Fxq "$target"; then
  target_dir="$REPO_ROOT/assignments/$target"
  if [ ! -d "$target_dir" ]; then
    echo "Error: assignment directory not found: $target_dir" >&2
    exit 1
  fi
  echo "Running Vcheck recursively under $target_dir"
  run_dir_recursive "$target_dir"
  exit $?
fi

if [ -f "$target" ]; then
  case "$target" in
    *.v) run_file "$target"; exit $? ;;
    *) echo "Error: file is not a .v: $target" >&2; exit 1 ;;
  esac
fi

if [ -d "$target" ]; then
  echo "Running Vcheck on .v files in $target (non-recursive)"
  run_dir_non_recursive "$target"
  exit $?
fi

echo "Error: target not found: $target" >&2
exit 1
