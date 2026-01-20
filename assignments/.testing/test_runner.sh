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
    if [ "$assignment" != "hw04" ]; then
      if [ "${#bench_files[@]}" -eq 0 ]; then
        echo "[FAIL] $(basename "$subdir"): no testbench found."
        overall_status=1
        continue
      fi
    fi

    checker_status=0
    checker_label="PASS"
    checker_log="verilog_checker.log"
    if [ "$assignment" = "hw04" ]; then
      checker_label="Not Applicable"
      if [ "$VERBOSE" -eq 1 ]; then
        echo "============================================================"
        echo "[CHECKER] $(basename "$subdir")"
        echo "------------------------------------------------------------"
        echo "[SKIP] Verilog checker not applicable for HW4."
      fi
    else
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
    fi

    sub_errors=0
    if [ "$assignment" = "hw04" ]; then
      shopt -s nullglob
      asm_files=(*.asm)
      shopt -u nullglob
      if [ "${#asm_files[@]}" -eq 0 ]; then
        echo "[FAIL] $(basename "$subdir"): no .asm files found."
        overall_status=1
        continue
      fi
      case "$(basename "$subdir")" in
        hw4_1)
          rm -f archsim.trace archsim.ptrace
          if [ ! -f "p1.txt" ]; then
            echo "[WARN] $(basename "$subdir"): p1.txt missing (manual grading expected)."
          else
            if ! grep -Eq '^[[:space:]]*([^/[:space:]]|/[^/])' "p1.txt"; then
              echo "[WARN] $(basename "$subdir"): p1.txt has no student content (manual grading expected)."
            fi
          fi
          ;;
        hw4_2)
          rm -f archsim.trace archsim.ptrace
          if [ ! -f "p2.txt" ]; then
            echo "[WARN] $(basename "$subdir"): p2.txt missing (manual grading expected)."
          else
            if ! grep -Eq '^[[:space:]]*([^/[:space:]]|/[^/])' "p2.txt"; then
              echo "[WARN] $(basename "$subdir"): p2.txt has no student content (manual grading expected)."
            fi
          fi
          ;;
      esac
      for asm in "${asm_files[@]}"; do
        asm_base="${asm%.asm}"
        asm_log="${asm_base}_asm.log"
        sim_log="${asm_base}_sim.log"
        tmpdir="$(mktemp -d)"
        out_prefix="$tmpdir/${asm_base}_loadfile"
        : >"$asm_log"
        : >"$sim_log"
        if [ "$VERBOSE" -eq 1 ]; then
          echo "============================================================"
          echo "[ASM] $(basename "$subdir") / $asm"
          echo "[CMD] /repo/assignments/tools/assembler/assemble.sh $asm $out_prefix"
        fi
        if ! /repo/assignments/tools/assembler/assemble.sh "$asm" "$out_prefix" >"$asm_log" 2>&1; then
          sub_errors=$((sub_errors + 1))
          [ "$VERBOSE" -eq 1 ] && cat "$asm_log"
          rm -rf "$tmpdir"
          continue
        fi
        if grep -qiE "unknown opcode|unknown register specifier|couldn't parse immediate value|bad hex number|labels must end with a colon|error opening|could not open|error in assemble" "$asm_log"; then
          sub_errors=$((sub_errors + 1))
          if [ "$VERBOSE" -eq 1 ]; then
            cat "$asm_log"
          fi
          rm -rf "$tmpdir"
          continue
        fi
        [ "$VERBOSE" -eq 1 ] && cat "$asm_log"

        sim_img=""
        if [ -f "${out_prefix}_all.img" ]; then
          sim_img="${out_prefix}_all.img"
        elif [ -f "${out_prefix}_0.img" ]; then
          sim_img="${out_prefix}_0.img"
        else
          sub_errors=$((sub_errors + 1))
          echo "[FAIL] $asm (no .img output found)" | tee -a "$sim_log"
          rm -rf "$tmpdir"
          continue
        fi

        if [ "$VERBOSE" -eq 1 ]; then
          echo "============================================================"
          echo "[SIM] $(basename "$subdir") / $asm"
          echo "[CMD] /repo/assignments/tools/simulator/wiscalculator $sim_img"
        fi

        if command -v timeout >/dev/null 2>&1; then
          if [ "$VERBOSE" -eq 1 ]; then
            timeout 5s /repo/assignments/tools/simulator/wiscalculator "$sim_img" 2>&1 | tee -a "$sim_log"
            sim_status="${PIPESTATUS[0]}"
          else
            timeout 5s /repo/assignments/tools/simulator/wiscalculator "$sim_img" >>"$sim_log" 2>&1
            sim_status=$?
          fi
        else
          if [ "$VERBOSE" -eq 1 ]; then
            /repo/assignments/tools/simulator/wiscalculator "$sim_img" 2>&1 | tee -a "$sim_log"
            sim_status="${PIPESTATUS[0]}"
          else
            /repo/assignments/tools/simulator/wiscalculator "$sim_img" >>"$sim_log" 2>&1
            sim_status=$?
          fi
        fi
        if [ "$VERBOSE" -eq 1 ]; then
          cat "$sim_log"
        fi
        if [ "$sim_status" -ne 0 ]; then
          if grep -qiE "program halted|program finished" "$sim_log"; then
            sim_status=0
          fi
        fi
        if [ "$sim_status" -eq 0 ]; then
          if ! grep -qiE "program halted|program finished" "$sim_log"; then
            sim_status=1
          fi
        fi
        if [ "$sim_status" -ne 0 ]; then
          sub_errors=$((sub_errors + 1))
          rm -rf "$tmpdir"
          continue
        fi
        rm -rf "$tmpdir"
      done
    else
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
    fi

    if [ "$sub_errors" -eq 0 ]; then
      if [ "$checker_status" -eq 0 ]; then
        echo "[PASS] $(basename "$subdir") (errors: 0; Legal syntax Check: $checker_label)"
      else
        echo "[FAIL] $(basename "$subdir") (errors: 0; Legal syntax Check: FAIL)"
        overall_status=1
      fi
    else
      echo "[FAIL] $(basename "$subdir") (errors: $sub_errors; Legal syntax Check: $([ "$checker_status" -eq 0 ] && echo "$checker_label" || echo FAIL))"
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
  echo "============================================================"
  echo "[ASSIGNMENT] $assignment"
  run_assignment "$assignment" "$subproblem"
fi
echo "================================================"

exit $overall_status
