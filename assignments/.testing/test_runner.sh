#!/usr/bin/env bash
set -euo pipefail

ASSIGN_ROOT="/repo/assignments"
VERBOSE=0

usage() {
  echo "Usage: ./run test [-v] <assignment> [subproblem]" >&2
  exit 1
}

if [ "${1:-}" = "-v" ]; then
  VERBOSE=1
  shift
fi

if [ $# -lt 1 ]; then
  usage
fi

assignment="$1"; shift
subproblem="${1:-}"

hw_dir="$ASSIGN_ROOT/$assignment"
# Allow "hw1" input to map to "hw01" if present.
if [ ! -d "$hw_dir" ] && [[ "$assignment" =~ ^hw([0-9]+)$ ]]; then
  num="${BASH_REMATCH[1]}"
  padded="$(printf "hw%02d" "$num")"
  if [ -d "$ASSIGN_ROOT/$padded" ]; then
    assignment="$padded"
    hw_dir="$ASSIGN_ROOT/$assignment"
  fi
fi

if [ ! -d "$hw_dir" ]; then
  echo "Assignment not found: $assignment" >&2
  exit 1
fi

if [ -n "$subproblem" ]; then
  subdirs=("$hw_dir/$subproblem")
else
  # All immediate subdirectories (e.g., hw1_1, hw1_2, ...)
  mapfile -t subdirs < <(find "$hw_dir" -maxdepth 1 -mindepth 1 -type d | sort)
fi

overall_status=0

for subdir in "${subdirs[@]}"; do
  if [ ! -d "$subdir" ]; then
    echo "Skipping missing subproblem: $subdir" >&2
    overall_status=1
    continue
  fi

  cd "$subdir"
  bench_files=(*_bench.v)
  if [ "${bench_files[0]}" = "*_bench.v" ]; then
    echo "[FAIL] $(basename "$subdir"): no testbench found."
    overall_status=1
    continue
  fi

  checker_status=0
  checker_log="verilog_checker.log"
  if [ "$VERBOSE" -eq 1 ]; then
    echo "============================================================"
    echo "[CHECKER] $(basename "$subdir")"
    echo "------------------------------------------------------------"
    echo "[CMD] verilog_checker $subdir"
  fi
  if ! bash /repo/verilog_checker.sh "$subdir" >"$checker_log" 2>&1; then
    checker_status=1
    [ "$VERBOSE" -eq 1 ] && cat "$checker_log"
  else
    [ "$VERBOSE" -eq 1 ] && cat "$checker_log"
  fi

  sub_errors=0
  for bench in "${bench_files[@]}"; do
    top="${bench%.v}"
    out="${top}.out"
    log="${top}.log"

    if [ "$VERBOSE" -eq 1 ]; then
      echo "============================================================"
      echo "[RUN] $(basename "$subdir") / $bench"
      echo "[CMD] iverilog -g2012 -s $top -o $out *.v"
    fi

    if ! iverilog -g2012 -s "$top" -o "$out" *.v >"$log" 2>&1; then
      sub_errors=$((sub_errors + 1))
      [ "$VERBOSE" -eq 1 ] && cat "$log"
      continue
    fi

    [ "$VERBOSE" -eq 1 ] && echo "[CMD] vvp $out"
    if [ "$VERBOSE" -eq 1 ]; then
      vvp "$out" 2>&1 | tee -a "$log"
    else
      vvp "$out" >>"$log" 2>&1
    fi
    if [ "${PIPESTATUS[0]}" -ne 0 ]; then
      sub_errors=$((sub_errors + 1))
      [ "$VERBOSE" -eq 1 ] && cat "$log"
      continue
    fi

    err_count=$(grep -c "ERRORCHECK" "$log" || true)
    sub_errors=$((sub_errors + err_count))
    if [ "$VERBOSE" -eq 1 ]; then
      if [ "$err_count" -gt 0 ]; then
        echo "[FAIL] $bench (errors: $err_count)"
      else
        echo "[PASS] $bench"
      fi
    fi
  done

  if [ "$sub_errors" -eq 0 ]; then
    if [ "$checker_status" -eq 0 ]; then
      echo "[PASS] $(basename "$subdir") (errors: 0; Legal syntax Check: PASS)"
    else
      echo "[FAIL] $(basename "$subdir") (errors: 0; Legal syntax Check: FAIL)"
      overall_status=1
    fi
  else
    echo "[FAIL] $(basename "$subdir") (errors: $sub_errors; Legal syntax Check: $([ "$checker_status" -eq 0 ] && echo PASS || echo FAIL))"
    overall_status=1
  fi
done

exit $overall_status
