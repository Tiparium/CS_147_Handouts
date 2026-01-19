#!/usr/bin/env bash
set -euo pipefail

ASSIGN_ROOT="/repo/assignments"
VERBOSE=0

usage() {
  echo "Usage: ./run test [-v] <assignment|all> [subproblem]" >&2
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

normalize_assignment() {
  local name="$1"
  local hw_dir="$ASSIGN_ROOT/$name"
  if [ ! -d "$hw_dir" ] && [[ "$name" =~ ^hw([0-9]+)$ ]]; then
    local num="${BASH_REMATCH[1]}"
    local padded
    padded="$(printf "hw%02d" "$num")"
    if [ -d "$ASSIGN_ROOT/$padded" ]; then
      name="$padded"
      hw_dir="$ASSIGN_ROOT/$name"
    fi
  fi
  printf "%s\n" "$name"
}

run_assignment() {
  local assignment="$1"
  local subproblem="${2:-}"
  local hw_dir="$ASSIGN_ROOT/$assignment"

  if [ ! -d "$hw_dir" ]; then
    echo "Assignment not found: $assignment" >&2
    overall_status=1
    return
  fi

  if [ -n "$subproblem" ]; then
    subdirs=("$hw_dir/$subproblem")
  else
    mapfile -t subdirs < <(find "$hw_dir" -maxdepth 1 -mindepth 1 -type d ! -name "Gradescope_Autograder_Template" | sort)
  fi

  for subdir in "${subdirs[@]}"; do
    if [ ! -d "$subdir" ]; then
      echo "Skipping missing subproblem: $subdir" >&2
      overall_status=1
      continue
    fi

    cd "$subdir"
    shopt -s nullglob
    bench_files=(*_bench.v tb_*.v)
    shopt -u nullglob
    if [ "${#bench_files[@]}" -eq 0 ]; then
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
        vvp "$out" <<<"finish" 2>&1 | tee -a "$log"
        vvp_status="${PIPESTATUS[0]}"
      else
        vvp "$out" <<<"finish" >>"$log" 2>&1
        vvp_status=$?
      fi
      if [ "$vvp_status" -ne 0 ]; then
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
}

overall_status=0

echo "================ TEST SUMMARY ================="
if [ "$assignment" = "all" ]; then
  mapfile -t assignments < <(find "$ASSIGN_ROOT" -maxdepth 1 -mindepth 1 -type d -name "hw*" | sort)
  if [ "${#assignments[@]}" -eq 0 ]; then
    echo "No assignments found under $ASSIGN_ROOT" >&2
    exit 1
  fi
  for hw_dir in "${assignments[@]}"; do
    hw_name="$(basename "$hw_dir")"
    echo "============================================================"
    echo "[ASSIGNMENT] $hw_name"
    run_assignment "$hw_name" ""
  done
else
  assignment="$(normalize_assignment "$assignment")"
  run_assignment "$assignment" "$subproblem"
fi
echo "================================================"

exit $overall_status
