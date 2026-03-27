#!/usr/bin/env bash
set -euo pipefail

ASSIGN_ROOT="/repo/assignments"
VERBOSE=0
INTERNAL=0
JUSTTIMER=0

usage() {
  echo "Usage: ./run test [-v] [-internal] [-justtimer] <assignment|all> [subproblem]" >&2
  exit 1
}

filtered_args=()
for arg in "$@"; do
  case "$arg" in
    -v) VERBOSE=1 ;;
    -internal) INTERNAL=1 ;;
    -justtimer) JUSTTIMER=1 ;;
    *) filtered_args+=("$arg") ;;
  esac
done
set -- "${filtered_args[@]}"

if [ $# -lt 1 ]; then
  usage
fi

assignment="$1"; shift
subproblem="${1:-}"
subtest="${2:-}"

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

hw4_template_only_asm() {
  local asm_file="$1"
  local stripped
  stripped="$(sed 's,//.*,,' "$asm_file" | tr -d '[:space:]')"
  [ -z "$stripped" ]
}

hw4_opcode_from_letter() {
  local letter="$1"
  local display="" regex=""
  case "$letter" in
    A) display="ROLI"; regex="ROLI" ;;
    B) display="SLLI"; regex="SLLI" ;;
    C) display="RORI"; regex="RORI" ;;
    D) display="SRLI"; regex="SRLI" ;;
    E) display="ST"; regex="ST" ;;
    F) display="LD"; regex="LD" ;;
    G) display="STU"; regex="STU" ;;
    H) display="BTR"; regex="BTR" ;;
    I) display="ROL"; regex="ROL" ;;
    J) display="SRL"; regex="SRL" ;;
    K) display="ROR"; regex="ROR" ;;
    L) display="SLL"; regex="SLL" ;;
    M) display="SEQ"; regex="SEQ" ;;
    N) display="SLT"; regex="SLT" ;;
    O) display="SLE"; regex="SLE" ;;
    Q) display="SCO"; regex="SCO" ;;
    R) display="SIIC or RTI"; regex="SIIC|RTI" ;;
    S) display="SLBI"; regex="SLBI" ;;
    T) display="JR"; regex="JR" ;;
    U) display="JAL"; regex="JAL" ;;
    V) display="JALR"; regex="JALR" ;;
    W) display="XOR or XORI"; regex="XOR|XORI" ;;
    X) display="ANDN or ANDNI"; regex="ANDN|ANDNI" ;;
  esac

  printf "%s|%s\n" "$display" "$regex"
}

hw4_asm_has_required_opcode() {
  local asm_file="$1"
  local opcode_regex="$2"
  sed 's,//.*,,' "$asm_file" | grep -qiE "(^|[^A-Za-z0-9_])(${opcode_regex})([^A-Za-z0-9_]|$)"
}

hw4_answer_section_has_content() {
  local file="$1"
  local start_pat="$2"
  local end_pat="${3:-}"
  awk -v start_pat="$start_pat" -v end_pat="$end_pat" '
    $0 ~ start_pat { in_section=1; next }
    in_section && end_pat != "" && $0 ~ end_pat { exit(found ? 0 : 1) }
    in_section {
      line=$0
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
      if (line == "" || line == "// Your answer here") next
      found=1
    }
    END { exit(found ? 0 : 1) }
  ' "$file"
}

hw5_check_required_file() {
  local file_path="$1"
  local display_path="$2"
  if [ -f "$file_path" ]; then
    echo "[x] $display_path"
    return 0
  fi
  echo "[ ] $display_path"
  return 1
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
    mapfile -t subdirs < <(find "$hw_dir" -maxdepth 1 -mindepth 1 -type d ! -name "Gradescope_Autograder_Template" ! -name "writeup" | sort)
  fi

  for subdir in "${subdirs[@]}"; do
    if [ ! -d "$subdir" ]; then
      echo "Skipping missing subproblem: $subdir" >&2
      overall_status=1
      continue
    fi
    if [ "$(basename "$subdir")" = "writeup" ]; then
      [ "$VERBOSE" -eq 1 ] && echo "[SKIP] writeup directory (no tests or Vcheck)."
      continue
    fi

    cd "$subdir"
    shopt -s nullglob
    bench_files=(*_bench.v tb_*.v)
    shopt -u nullglob
    if [ "$assignment" != "hw04" ] && [ "$assignment" != "hw05" ]; then
      if [ "${#bench_files[@]}" -eq 0 ]; then
        echo "[FAIL] $(basename "$subdir"): no testbench found."
        overall_status=1
        continue
      fi
    fi

    checker_status=0
    checker_label="PASS"
    checker_log="verilog_checker.log"
    if [ "$assignment" = "hw04" ] || [ "$assignment" = "hw05" ]; then
      checker_label="Not Applicable"
      if [ "$VERBOSE" -eq 1 ]; then
        echo "============================================================"
        echo "[CHECKER] $(basename "$subdir")"
        echo "------------------------------------------------------------"
        echo "[SKIP] Verilog checker not applicable for $assignment."
      fi
    else
      if [ "$VERBOSE" -eq 1 ]; then
        echo "============================================================"
        echo "[CHECKER] $(basename "$subdir")"
        echo "------------------------------------------------------------"
        echo "[CMD] verilog_checker $subdir"
      fi
      if ! bash /repo/scripts/verilog_checker/verilog_checker.sh "$subdir" >"$checker_log" 2>&1; then
        checker_status=1
        [ "$VERBOSE" -eq 1 ] && cat "$checker_log"
      else
        [ "$VERBOSE" -eq 1 ] && cat "$checker_log"
      fi
    fi

    sub_errors=0
    if [ "$assignment" = "hw05" ]; then
      case "$(basename "$subdir")" in
        hw5_1|hw5_2)
          if ! hw5_check_required_file "schematic.pdf" "$(basename "$subdir")/schematic.pdf"; then
            sub_errors=$((sub_errors + 1))
          fi
          if ! hw5_check_required_file "cacheFSM.pdf" "$(basename "$subdir")/cacheFSM.pdf"; then
            sub_errors=$((sub_errors + 1))
          fi
          ;;
        *)
          echo "[ERROR] $(basename "$subdir"): unknown HW5 subproblem."
          sub_errors=$((sub_errors + 1))
          ;;
      esac
    elif [ "$assignment" = "hw04" ]; then
      shopt -s nullglob
      asm_files=(*.asm)
      shopt -u nullglob
      if [ "${#asm_files[@]}" -eq 0 ]; then
        echo "[ERROR] $(basename "$subdir"): no .asm files found."
        overall_status=1
        continue
      fi
      hw4_targets_ready=1
      asm_idx=0
      hw4_target_letters=()
      case "$(basename "$subdir")" in
        hw4_1)
          rm -f archsim.trace archsim.ptrace
          if [ ! -f "targets.txt" ]; then
            echo "[ERROR] $(basename "$subdir"): no expected opcodes found. Run ./run generate hw4 first."
            hw4_targets_ready=0
            sub_errors=$((sub_errors + 1))
          else
            while IFS= read -r line; do
              line="${line%%#*}"
              line="$(printf "%s" "$line" | tr -d '[:space:]')"
              [ -z "$line" ] && continue
              line="$(printf "%s" "$line" | tr '[:lower:]' '[:upper:]')"
              case "$line" in
                A|B|C|D|E|F|G|H|I|J|K|L|M|N|O|Q|R|S|T|U|V|W|X)
                  hw4_target_letters+=("$line")
                  ;;
                *)
                  echo "[ERROR] $(basename "$subdir"): invalid target letter '$line' in targets.txt"
                  sub_errors=$((sub_errors + 1))
                  hw4_targets_ready=0
                  ;;
              esac
            done < "targets.txt"
            if [ ${#hw4_target_letters[@]} -eq 0 ]; then
              echo "[ERROR] $(basename "$subdir"): no expected opcodes found. Run ./run generate hw4 first."
              hw4_targets_ready=0
              sub_errors=$((sub_errors + 1))
            fi
          fi
          if [ ! -f "p1_answers.txt" ]; then
            echo "[ERROR] $(basename "$subdir"): p1_answers.txt missing."
            sub_errors=$((sub_errors + 1))
          else
            if ! grep -Eq '^[[:space:]]*HW4_1_2[[:space:]]+Answer:[[:space:]]*$' "p1_answers.txt"; then
              echo "[ERROR] $(basename "$subdir"): p1_answers.txt missing required header 'HW4_1_2 Answer:'."
              sub_errors=$((sub_errors + 1))
            elif ! hw4_answer_section_has_content "p1_answers.txt" '^[[:space:]]*HW4_1_2[[:space:]]+Answer:[[:space:]]*$'; then
              echo "[ERROR] $(basename "$subdir"): p1_answers.txt has no answer content for HW4_1_2."
              sub_errors=$((sub_errors + 1))
            fi
          fi
          ;;
        hw4_2)
          rm -f archsim.trace archsim.ptrace
          if [ ! -f "p2_answers.txt" ]; then
            echo "[ERROR] $(basename "$subdir"): p2_answers.txt missing."
            sub_errors=$((sub_errors + 1))
          else
            if ! grep -Eq '^[[:space:]]*HW4_2_2[[:space:]]+Answer:[[:space:]]*$' "p2_answers.txt"; then
              echo "[ERROR] $(basename "$subdir"): p2_answers.txt missing header 'HW4_2_2 Answer:'."
              sub_errors=$((sub_errors + 1))
            fi
            if ! grep -Eq '^[[:space:]]*HW4_2_3[[:space:]]+Answer:[[:space:]]*$' "p2_answers.txt"; then
              echo "[ERROR] $(basename "$subdir"): p2_answers.txt missing header 'HW4_2_3 Answer:'."
              sub_errors=$((sub_errors + 1))
            fi
            if ! hw4_answer_section_has_content "p2_answers.txt" '^[[:space:]]*HW4_2_2[[:space:]]+Answer:[[:space:]]*$' '^[[:space:]]*HW4_2_3[[:space:]]+Answer:[[:space:]]*$'; then
              echo "[ERROR] $(basename "$subdir"): p2_answers.txt has no answer content for HW4_2_2."
              sub_errors=$((sub_errors + 1))
            fi
            if ! hw4_answer_section_has_content "p2_answers.txt" '^[[:space:]]*HW4_2_3[[:space:]]+Answer:[[:space:]]*$'; then
              echo "[ERROR] $(basename "$subdir"): p2_answers.txt has no answer content for HW4_2_3."
              sub_errors=$((sub_errors + 1))
            fi
          fi
          ;;
      esac
      for asm in "${asm_files[@]}"; do
        required_opcode_display=""
        required_opcode_regex=""
        if [ "$(basename "$subdir")" = "hw4_1" ] && [ "$hw4_targets_ready" -eq 1 ]; then
          if [ $asm_idx -ge ${#hw4_target_letters[@]} ]; then
            echo "[ERROR] $asm (missing assigned target for this test in targets.txt)"
            sub_errors=$((sub_errors + 1))
          else
            target_letter="${hw4_target_letters[$asm_idx]}"
            IFS='|' read -r required_opcode_display required_opcode_regex <<<"$(hw4_opcode_from_letter "$target_letter")"
            if [ -z "$required_opcode_display" ] || [ -z "$required_opcode_regex" ]; then
              echo "[ERROR] $asm (invalid assigned target '$target_letter' in targets.txt)"
              sub_errors=$((sub_errors + 1))
            else
              echo "[info] Required Opcode: $required_opcode_display"
            fi
          fi
          asm_idx=$((asm_idx + 1))
        fi

        if hw4_template_only_asm "$asm"; then
          echo "[ERROR] $asm (template/empty asm file; no credit for this problem)"
          sub_errors=$((sub_errors + 1))
        fi
        if [ "$(basename "$subdir")" = "hw4_1" ] && [ -n "$required_opcode_regex" ]; then
          if ! hw4_asm_has_required_opcode "$asm" "$required_opcode_regex"; then
            echo "[ERROR] $asm (missing required opcode: $required_opcode_display; no credit for this problem)"
            sub_errors=$((sub_errors + 1))
          fi
        fi

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
          echo "[ERROR] $asm (no .img output found)" | tee -a "$sim_log"
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

run_project() {
  local phase="${1:-}"
  local action="${2:-}"
  local internal="${3:-0}"
  local project_root="$ASSIGN_ROOT/project"
  local project_wsrun="$project_root/wsrun_iverilog.sh"
  local test_root="$project_root/testprograms/public"
  local out_root="$project_root/.wsrun_out"
  local tb=""
  local demo_dir=""
  local list_dirs=()
  local summary_jsonl=""
  emit_internal_group() {
    local key="$1"
    local label="$2"
    python3 - <<'PY' "$key" "$label"
import json,sys
print(json.dumps({
  "type":"group",
  "group_key":sys.argv[1],
  "group_label":sys.argv[2]
}, indent=2))
PY
  }
  emit_internal_summary() {
    python3 - <<'PY' "$1" "$2" "$3" "$4" "$5" "$6"
import json,sys
print(json.dumps({
  "type":"summary",
  "supplied":{"tests":int(sys.argv[1]),"passed":int(sys.argv[2]),"failed":int(sys.argv[3])},
  "student_custom":{"tests":int(sys.argv[4]),"passed":int(sys.argv[5]),"failed":int(sys.argv[6])},
  "scored_tests":"supplied_only"
}, indent=2))
PY
  }
  list_file_for_dir() {
    local d="$1"
    if [ "$d" = "student_custom" ]; then
      printf "%s\n" "$project_root/testprograms/student_custom/all.list"
    else
      printf "%s\n" "$test_root/$d/all.list"
    fi
  }
  is_list_entry() {
    local trimmed
    trimmed="$(printf "%s" "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [ -n "$trimmed" ] || return 1
    case "$trimmed" in
      \#*) return 1 ;;
    esac
    return 0
  }

  if [ -z "$phase" ]; then
    echo "Usage: ./run test project phase_1 [list|<test>]" >&2
    overall_status=1
    return
  fi

  case "$phase" in
    phase_1)
      tb="proc_hier_bench"
      demo_dir="$project_root/demo1/verilog"
      list_dirs=(student_custom inst_tests complex_demo1 rand_simple rand_complex rand_ctrl rand_mem)
      ;;
    phase_2|phase_3)
      echo "[project] $phase tests are not wired yet."
      return
      ;;
    "")
      echo "Usage: ./run test project phase_1 [list|<test>] or ./run test project [phase]" >&2
      overall_status=1
      return
      ;;
    *)
      echo "Unknown project phase: $phase" >&2
      overall_status=1
      return
      ;;
  esac

  if [ ! -x "$project_wsrun" ]; then
    echo "Missing wsrun_iverilog.sh: $project_wsrun" >&2
    overall_status=1
    return
  fi

  if [ ! -d "$demo_dir" ]; then
    echo "Missing demo directory: $demo_dir" >&2
    overall_status=1
    return
  fi

  # Ensure per-phase output directory exists before writing summary artifacts.
  mkdir -p "$out_root/$phase"

  if [ "$action" = "list" ]; then
    # Group by test categories instead of listing individual .asm files.
    simple_dir="inst_tests"
    complex_dir="complex_demo1"
    rand_dirs=(rand_simple rand_complex rand_ctrl rand_mem)
    custom_dir="student_custom"

    if [ -f "$(list_file_for_dir "$custom_dir")" ]; then
      echo "1. Student custom tests"
      echo "   - $custom_dir"
    else
      echo "1. Student custom tests (missing list)" >&2
      overall_status=1
    fi

    if [ -f "$(list_file_for_dir "$simple_dir")" ]; then
      echo "2. Simple instruction tests"
    else
      echo "2. Simple instruction tests (missing list)" >&2
      overall_status=1
    fi

    if [ -f "$(list_file_for_dir "$complex_dir")" ]; then
      echo "3. Complex tests for demo1"
    else
      echo "3. Complex tests for demo1 (missing list)" >&2
      overall_status=1
    fi

    echo "4. Random tests for demo1"
    for d in "${rand_dirs[@]}"; do
      if [ -f "$(list_file_for_dir "$d")" ]; then
        echo "   - $d"
      else
        echo "   - $d (missing list)" >&2
        overall_status=1
      fi
    done
    return
  fi

  if [ "$JUSTTIMER" -eq 1 ]; then
    local justtimer_total=0
    local justtimer_index=0
    local spinner_label=""
    local spinner_label_file=""
    local suite_start_ts=""
    source "/repo/scripts/spinner.sh"
    if [ -n "$action" ]; then
      test_name="$action"
      case "$test_name" in
        *.asm) ;;
        *) test_name="${test_name}.asm" ;;
      esac
      found=""
      for d in "${list_dirs[@]}"; do
        list_file="$(list_file_for_dir "$d")"
        [ -f "$list_file" ] || continue
        while IFS= read -r line; do
          is_list_entry "$line" || continue
          base="${line##*/}"
          if [ "$base" = "$test_name" ]; then
            found="$(dirname "$list_file")/$test_name"
            break
          fi
        done < "$list_file"
        [ -n "$found" ] && break
      done
      if [ -z "$found" ]; then
        echo "Test not found in phase lists: $test_name" >&2
        overall_status=1
        return
      fi
      justtimer_total=1
    else
      for d in "${list_dirs[@]}"; do
        list_file="$(list_file_for_dir "$d")"
        [ -f "$list_file" ] || continue
        while IFS= read -r line; do
          is_list_entry "$line" || continue
          justtimer_total=$((justtimer_total + 1))
        done < "$list_file"
      done
    fi

    if [ "$justtimer_total" -eq 0 ]; then
      echo "No tests found for $phase." >&2
      overall_status=1
      return
    fi

    echo "[INFO] justtimer mode: simulating ${justtimer_total} tests (0.2s each); no tests executed."
    suite_start_ts="$(date +%s)"
    spinner_label_file="$(mktemp -t justtimer_spinner_label.XXXXXX 2>/dev/null || mktemp "/tmp/justtimer_spinner_label.XXXXXX")"
    if [ -n "$spinner_label_file" ]; then
      export SPINNER_LABEL_FILE="$spinner_label_file"
    fi
    spinner_label="Running test suite (0/${justtimer_total}, failed: 0)"
    if [ -n "$spinner_label_file" ]; then
      printf "%s" "$spinner_label" > "$spinner_label_file" 2>/dev/null || true
    fi
    spinner_start "$spinner_label" "$suite_start_ts"

    if [ -n "$action" ]; then
      base="${test_name%.asm}"
      sleep 0.2
      justtimer_index=1
      spinner_label="Running test suite (${justtimer_index}/${justtimer_total}, failed: 0)"
      if [ -n "$spinner_label_file" ]; then
        printf "%s" "$spinner_label" > "$spinner_label_file" 2>/dev/null || true
      fi
      spinner_pause
      printf "  [SKIP] %-15s | [ERRORS] total: N/A*   asm: N/A*  cmp: N/A*  sim: N/A* diff: N/A*   vcheck: N/A*\n" "$base"
      spinner_resume
    else
      for d in "${list_dirs[@]}"; do
        list_file="$(list_file_for_dir "$d")"
        case "$d" in
          inst_tests) group_label="Simple instruction tests" ;;
          complex_demo1) group_label="Complex tests for demo1" ;;
          rand_simple|rand_complex|rand_ctrl|rand_mem) group_label="Random tests for demo1 ($d)" ;;
          student_custom) group_label="Student custom tests" ;;
          *) group_label="$d" ;;
        esac
        echo "[GROUP] $group_label"
        if [ ! -f "$list_file" ]; then
          continue
        fi
        while IFS= read -r line; do
          is_list_entry "$line" || continue
          base="${line##*/}"
          name="${base%.asm}"
          sleep 0.2
          justtimer_index=$((justtimer_index + 1))
          spinner_label="Running test suite (${justtimer_index}/${justtimer_total}, failed: 0)"
          if [ -n "$spinner_label_file" ]; then
            printf "%s" "$spinner_label" > "$spinner_label_file" 2>/dev/null || true
          fi
          spinner_pause
          printf "  [SKIP] %-15s | [ERRORS] total: N/A*   asm: N/A*  cmp: N/A*  sim: N/A* diff: N/A*   vcheck: N/A*\n" "$name"
          spinner_resume
        done < "$list_file"
        echo ""
      done
    fi

    spinner_stop_quiet || true
    if [ -n "$spinner_label_file" ]; then
      rm -f "$spinner_label_file" || true
      unset SPINNER_LABEL_FILE
    fi
    return
  fi

  if [ -n "$action" ]; then
    test_name="$action"
    case "$test_name" in
      *.asm) ;;
      *) test_name="${test_name}.asm" ;;
    esac
    found=""
    for d in "${list_dirs[@]}"; do
      list_file="$(list_file_for_dir "$d")"
      [ -f "$list_file" ] || continue
      while IFS= read -r line; do
        is_list_entry "$line" || continue
        base="${line##*/}"
        if [ "$base" = "$test_name" ]; then
          found="$(dirname "$list_file")/$test_name"
          break
        fi
      done < "$list_file"
      [ -n "$found" ] && break
    done
    if [ -z "$found" ]; then
      echo "Test not found in phase lists: $test_name" >&2
      overall_status=1
      return
    fi
    : > "$out_root/$phase/summary.log"
    summary_jsonl="$out_root/$phase/summary.jsonl"
    name_width="${#test_name}"
    WSRUN_STREAM=$([ "$internal" -eq 1 ] && echo "json_pretty" || echo "pretty") \
      WSRUN_SPINNER=1 WSRUN_SPINNER_SCOPE=run WSRUN_NAME_WIDTH="$name_width" \
      WSRUN_VERBOSE="$VERBOSE" \
      "$project_wsrun" -outdir "$out_root/$phase" -prog "$found" "$tb" "$demo_dir"/*.v
    rc=$?
    if [ "$rc" -ne 0 ]; then
      overall_status=1
      return
    fi
    if [ "$internal" -eq 0 ] && [ -f "$summary_jsonl" ]; then
      total_count="$(wc -l < "$summary_jsonl" | tr -d ' ')"
      if [ "${total_count:-0}" -gt 1 ]; then
        python3 - <<'PY' "$summary_jsonl"
import json,sys
total=0
passed=0
failed=0
for line in open(sys.argv[1]):
    line=line.strip()
    if not line:
        continue
    total += 1
    try:
        obj=json.loads(line)
    except json.JSONDecodeError:
        continue
    if obj.get("status") == "PASS":
        passed += 1
    else:
        failed += 1
print(f"[SUMMARY] tests: {total}  passed: {passed}  failed: {failed}")
PY
      fi
    fi
    return
  fi

  summary_jsonl="$out_root/$phase/summary.jsonl"
  summary_all_jsonl="$out_root/$phase/summary_all.jsonl"
  : > "$summary_all_jsonl"
  suite_start_ts="$(date +%s)"
  supplied_total=0
  supplied_pass=0
  supplied_fail=0
  student_total=0
  student_pass=0
  student_fail=0
  phase_total=0
  supplied_phase_total=0
  student_phase_total=0
  max_name_len=0
  for d in "${list_dirs[@]}"; do
    list_file="$(list_file_for_dir "$d")"
    [ -f "$list_file" ] || continue
    while IFS= read -r line; do
      is_list_entry "$line" || continue
      base="${line##*/}"
      name="${base%.asm}"
      if [ "${#name}" -gt "$max_name_len" ]; then
        max_name_len="${#name}"
      fi
      phase_total=$((phase_total + 1))
      if [ "$d" = "student_custom" ]; then
        student_phase_total=$((student_phase_total + 1))
      else
        supplied_phase_total=$((supplied_phase_total + 1))
      fi
    done < "$list_file"
  done
  done_count=0
  fail_count=0
  supplied_done_count=0
  student_done_count=0
  supplied_fail_count=0
  student_fail_count=0
  for d in "${list_dirs[@]}"; do
    list_file="$(list_file_for_dir "$d")"
    group_count=0
    if [ -f "$list_file" ]; then
      group_count="$(awk '!/^[[:space:]]*($|#)/{c++} END{print c+0}' "$list_file" 2>/dev/null || true)"
    fi
    case "$d" in
      inst_tests) group_label="Simple instruction tests" ;;
      complex_demo1) group_label="Complex tests for demo1" ;;
      rand_simple|rand_complex|rand_ctrl|rand_mem) group_label="Random tests for demo1 ($d)" ;;
      student_custom) group_label="Student custom tests" ;;
      *) group_label="$d" ;;
    esac
    if [ "$internal" -eq 1 ]; then
      emit_internal_group "$d" "$group_label"
    else
      echo "[GROUP] $group_label"
    fi
    if [ ! -f "$list_file" ]; then
      if [ "$internal" -eq 0 ]; then
        echo ""
      fi
      continue
    fi
    if [ "${group_count:-0}" -eq 0 ]; then
      if [ "$internal" -eq 0 ]; then
        echo "  [INFO] No tests configured."
        echo ""
      fi
      continue
    fi
    group_summary_jsonl="$out_root/$phase/.group_${d}.jsonl"
    : > "$group_summary_jsonl"
    spinner_total="$supplied_phase_total"
    spinner_offset="$supplied_done_count"
    spinner_fail_base="$supplied_fail_count"
    spinner_label="Running official tests"
    if [ "$d" = "student_custom" ]; then
      spinner_total="$student_phase_total"
      spinner_offset="$student_done_count"
      spinner_fail_base="$student_fail_count"
      spinner_label="Running student tests"
    fi
    WSRUN_STREAM=$([ "$internal" -eq 1 ] && echo "json_pretty" || echo "pretty") \
      WSRUN_SPINNER=1 WSRUN_SPINNER_SCOPE=run WSRUN_NAME_WIDTH="$max_name_len" \
      WSRUN_VERBOSE="$VERBOSE" WSRUN_PHASE="$phase" WSRUN_LINE_PREFIX="  " \
      WSRUN_SUMMARY_JSONL="$group_summary_jsonl" WSRUN_SUMMARY_APPEND=1 \
      WSRUN_TOTAL_TESTS="$spinner_total" WSRUN_INDEX_OFFSET="$spinner_offset" WSRUN_FAIL_BASE="$spinner_fail_base" \
      WSRUN_SPINNER_LABEL_PREFIX="$spinner_label" \
      WSRUN_SPINNER_START_TS="$suite_start_ts" \
      "$project_wsrun" -outdir "$out_root/$phase" -list "$list_file" "$tb" "$demo_dir"/*.v
    rc=$?
    if [ "$rc" -ne 0 ]; then
      overall_status=1
      break
    fi
    done_count=$((done_count + group_count))
    cat "$group_summary_jsonl" >> "$summary_all_jsonl"
    group_totals="$(python3 - <<'PY' "$group_summary_jsonl"
import json,sys
total=0
passed=0
failed=0
for line in open(sys.argv[1]):
    line=line.strip()
    if not line:
        continue
    total += 1
    try:
        obj=json.loads(line)
    except json.JSONDecodeError:
        continue
    if obj.get("status") == "PASS":
        passed += 1
    else:
        failed += 1
print(total, passed, failed)
PY
)"
    g_total=0
    g_pass=0
    g_fail=0
    read -r g_total g_pass g_fail <<< "$group_totals"
    if [ "$d" = "student_custom" ]; then
      student_total=$((student_total + g_total))
      student_pass=$((student_pass + g_pass))
      student_fail=$((student_fail + g_fail))
      student_done_count=$((student_done_count + g_total))
      student_fail_count=$((student_fail_count + g_fail))
    else
      supplied_total=$((supplied_total + g_total))
      supplied_pass=$((supplied_pass + g_pass))
      supplied_fail=$((supplied_fail + g_fail))
      supplied_done_count=$((supplied_done_count + g_total))
      supplied_fail_count=$((supplied_fail_count + g_fail))
    fi
    if [ -f "$summary_all_jsonl" ]; then
      fail_count="$(python3 - <<'PY' "$summary_all_jsonl"
import json,sys
failed=0
for line in open(sys.argv[1]):
    line=line.strip()
    if not line:
        continue
    try:
        obj=json.loads(line)
    except json.JSONDecodeError:
        continue
    if obj.get("status") != "PASS":
        failed += 1
print(failed)
PY
)"
    fi
    echo ""
  done
  if [ "$internal" -eq 0 ] && [ -f "$summary_all_jsonl" ]; then
    total_count="$(wc -l < "$summary_all_jsonl" | tr -d ' ')"
    if [ "${total_count:-0}" -gt 1 ]; then
      echo "[SUMMARY] supplied tests: ${supplied_total}  passed: ${supplied_pass}  failed: ${supplied_fail}"
      echo "[SUMMARY] student tests:  ${student_total}  passed: ${student_pass}  failed: ${student_fail}"
      echo "[SUMMARY] scored tests: supplied only"
    fi
  elif [ "$internal" -eq 1 ]; then
    emit_internal_summary "$supplied_total" "$supplied_pass" "$supplied_fail" "$student_total" "$student_pass" "$student_fail"
  fi
}

overall_status=0

summary_border="============================================================"
summary_label="TEST SUMMARY"
pad_len=$(( (${#summary_border} - ${#summary_label} - 2) / 2 ))
pad_left="$(printf '%*s' "$pad_len" "" | tr ' ' '=')"
pad_right="$(printf '%*s' "$pad_len" "" | tr ' ' '=')"
if [ $(( (${#summary_border} - ${#summary_label} - 2) % 2 )) -ne 0 ]; then
  pad_right="${pad_right}="
fi
echo "${pad_left} ${summary_label} ${pad_right}"
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
  if [ "$assignment" = "project" ]; then
    if [ -z "$subproblem" ]; then
      echo "[NOTE] '*' indicates error count is not comprehensive, because some tests could not be run."
      echo "[WARN] Project test suite may take a significant amount of time to run."
      echo "       It is safe to abort this process (via ctrl + c),"
      echo "       but doing so will invalidate the current test run."
      echo "[WARN] Do not make edits to any files while the test suite is running."
      echo "       Doing so will cause the testing run to break."
    elif [ -z "$subtest" ]; then
      case "$subproblem" in
        phase_1|phase_2|phase_3)
          echo "[NOTE] '*' indicates error count is not comprehensive, because some tests could not be run."
          echo "[WARN] Project test suite may take a significant amount of time to run."
          echo "       It is safe to abort this process (via ctrl + c),"
          echo "       but doing so will invalidate the current test run."
          echo "[WARN] Do not make edits to any files while the test suite is running."
          echo "       Doing so will cause the testing run to break."
          ;;
      esac
    fi
    echo "============================================================"
    if [ -z "$subproblem" ]; then
      echo "[ASSIGNMENT] project: Phase 1"
      run_project "phase_1" "" "$INTERNAL"
      echo "[ASSIGNMENT] project: Phase 2"
      run_project "phase_2" "" "$INTERNAL"
      echo "[ASSIGNMENT] project: Phase 3"
      run_project "phase_3" "" "$INTERNAL"
    else
      case "$subproblem" in
        phase_1) phase_label="Phase 1" ;;
        phase_2) phase_label="Phase 2" ;;
        phase_3) phase_label="Phase 3" ;;
        *) phase_label="$subproblem" ;;
      esac
      echo "[ASSIGNMENT] project: $phase_label"
      run_project "$subproblem" "$subtest" "$INTERNAL"
    fi
  else
    assignment="$(normalize_assignment "$assignment")"
    echo "============================================================"
    echo "[ASSIGNMENT] $assignment"
    run_assignment "$assignment" "$subproblem"
  fi
fi
echo "================================================"

exit $overall_status
