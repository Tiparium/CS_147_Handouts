#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ ! -f "/.dockerenv" ]; then
  echo "ERROR: wsrun_iverilog.sh must be run inside the container. Use ./run test project ..." >&2
  exit 1
fi
REPO_ROOT="/repo"
PROJECT_ROOT="$REPO_ROOT/assignments/project"

brief=0
verbose="${WSRUN_VERBOSE:-0}"
stream_mode="${WSRUN_STREAM:-pretty}" # pretty|json|json_pretty|none
spinner="${WSRUN_SPINNER:-0}"
spinner_scope="${WSRUN_SPINNER_SCOPE:-run}" # run|test
sim_timeout_secs="${WSRUN_SIM_TIMEOUT_SECS:-15}"
max_failures=10
pipeline_mode=0
aligned=0
line_prefix="${WSRUN_LINE_PREFIX:-}"
list_file=""
list_dir=""
prog_list=()
out_base="$PROJECT_ROOT/.wsrun_out"
testprograms_root="${TESTPROGRAMS_ROOT:-$PROJECT_ROOT/testprograms}"
ASSEMBLE_CMD=("/repo/assignments/tools/assembler/assemble.sh")
SIMULATE_CMD=("/repo/assignments/tools/simulator/wiscalculator")
IVERILOG_CMD=("iverilog")
VVP_CMD=("vvp")

usage() {
  cat <<'USAGE' >&2
Usage: wsrun_iverilog.sh [options] <tb_top> <verilog files...>
Options:
  -list <file>     Run all .asm files listed in <file>
  -prog <file>     Run a single .asm (may be repeated)
  -maxf <n>        Stop after n failures (default: 10)
  -brief           Reduce console output
  -pipe            Expect pipelined trace (.ptrace)
  -align           Pass -align to simulator
  -outdir <dir>    Base output directory (default: assignments/project/.wsrun_out)
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    -brief) brief=1; shift ;;
    -maxf) shift; max_failures="${1:-}"; shift ;;
    -pipe) pipeline_mode=1; shift ;;
    -align) aligned=1; shift ;;
    -list) shift; list_file="${1:-}"; shift ;;
    -prog) shift; prog_list+=("${1:-}"); shift ;;
    -outdir) shift; out_base="${1:-}"; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) echo "Unknown option: $1" >&2; usage; exit 1 ;;
    *) break ;;
  esac
done

if [ $# -lt 2 ]; then
  usage
  exit 1
fi

tb_top="$1"; shift
include_syn="${INCLUDE_SYN_V:-0}"
verilog_files=()
for vf in "$@"; do
  case "$vf" in
    *.syn.v)
      if [ "$include_syn" = "1" ]; then
        verilog_files+=("$vf")
      fi
      ;;
    *) verilog_files+=("$vf") ;;
  esac
done

if [ -n "$list_file" ]; then
  if [ ! -f "$list_file" ]; then
    echo "List file not found: $list_file" >&2
    exit 1
  fi
  list_dir="$(python3 -c 'import os,sys; print(os.path.abspath(os.path.dirname(sys.argv[1])))' "$list_file")"
  while IFS= read -r line; do
    trimmed="$(printf "%s" "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [ -n "$trimmed" ] || continue
    case "$trimmed" in
      \#*) continue ;;
    esac
    prog_list+=("$trimmed")
  done < "$list_file"
fi

if [ ${#prog_list[@]} -eq 0 ]; then
  echo "No -prog or -list provided. Nothing to run." >&2
  exit 1
fi

mkdir -p "$out_base"
run_root="$out_base"

trace_ext=".trace"
if [ "$pipeline_mode" -eq 1 ]; then
  trace_ext=".ptrace"
fi

# Convert a host path under repo to its /repo counterpart for container use.
repo_path() {
  local host_path
  host_path="$(python3 -c 'import os,sys; print(os.path.abspath(sys.argv[1]))' "$1")"
  case "$host_path" in
    /repo/*) printf "%s" "$host_path" ;;
    *) echo "ERROR: path not under /repo: $host_path" >&2; exit 1 ;;
  esac
}

normalize_prog_path() {
  local raw="$1"
  local trimmed
  trimmed="$(printf "%s" "$raw" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  if [ -z "$trimmed" ]; then
    echo ""
    return
  fi
  if [ -f "$trimmed" ]; then
    python3 -c 'import os,sys; print(os.path.abspath(sys.argv[1]))' "$trimmed"
    return
  fi
  if [ -n "$list_dir" ] && [ -f "$list_dir/$trimmed" ]; then
    python3 -c 'import os,sys; print(os.path.abspath(sys.argv[1]))' "$list_dir/$trimmed"
    return
  fi
  if [[ "$trimmed" == *"/testprograms/"* ]]; then
    local suffix="${trimmed#*/testprograms/}"
    local mapped="$testprograms_root/$suffix"
    if [ -f "$mapped" ]; then
      python3 -c 'import os,sys; print(os.path.abspath(sys.argv[1]))' "$mapped"
      return
    fi
  fi
  echo "$trimmed"
}

verilog_files_repo=()
for vf in "${verilog_files[@]}"; do
  verilog_files_repo+=("$(repo_path "$vf")")
done
common_verilog_dir="$PROJECT_ROOT/common/verilog"
if [ -d "$common_verilog_dir" ]; then
  for vf in "$common_verilog_dir"/*.v; do
    [ -f "$vf" ] || continue
    case "$(basename "$vf")" in
      regFile*.v) continue ;;
      *_hier.v) continue ;;
    esac
    verilog_files_repo+=("$vf")
  done
fi

summary_jsonl="${WSRUN_SUMMARY_JSONL:-$run_root/summary.jsonl}"
if [ "${WSRUN_SUMMARY_APPEND:-0}" -eq 0 ]; then
  : > "$summary_jsonl"
fi
vcheck_log="$run_root/vcheck.log"
vcheck_status="Not Applicable"
vcheck_errors=0
vcheck_phase="${WSRUN_PHASE:-}"

if [ "$spinner" -eq 1 ]; then
  # shellcheck source=/dev/null
  source "/repo/scripts/spinner.sh"
fi

# Compute max test-name width for aligned output.
if [ -n "${WSRUN_NAME_WIDTH:-}" ]; then
  max_name_len="$WSRUN_NAME_WIDTH"
else
  if [ "$spinner" -eq 1 ] && [ "$spinner_scope" = "run" ]; then
    spinner_start "Preparing test list"
  fi
  max_name_len=0
  for prog in "${prog_list[@]}"; do
    prog_trimmed="$(printf "%s" "$prog" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [ -z "$prog_trimmed" ] && continue
    prog_host="$(normalize_prog_path "$prog_trimmed")"
    prog_base="$(basename "$prog_host")"
    prog_name="${prog_base%.asm}"
    if [ "${#prog_name}" -gt "$max_name_len" ]; then
      max_name_len="${#prog_name}"
    fi
  done
  if [ "$spinner" -eq 1 ] && [ "$spinner_scope" = "run" ]; then
    spinner_stop_quiet
  fi
fi
total_tests="${WSRUN_TOTAL_TESTS:-0}"
if [ "$total_tests" -le 0 ]; then
  total_tests=0
  for prog in "${prog_list[@]}"; do
    prog_trimmed="$(printf "%s" "$prog" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [ -z "$prog_trimmed" ] && continue
    total_tests=$((total_tests + 1))
  done
fi
pad="   "

cleanup_on_exit() {
  if [ "$spinner" -eq 1 ]; then
    spinner_stop_quiet || true
  fi
  if [ -n "${spinner_label_file:-}" ] && [ -f "$spinner_label_file" ]; then
    rm -f "$spinner_label_file" || true
  fi
}
trap 'cleanup_on_exit' EXIT
request_stop=0
sigint_count=0
interrupted=0
handle_sigint() {
  sigint_count=$((sigint_count + 1))
  if [ "$sigint_count" -ge 2 ]; then
    if [ "$spinner" -eq 1 ]; then
      spinner_abort || true
    fi
    kill -- -$$ >/dev/null 2>&1 || true
    exit 130
  fi
  request_stop=1
  interrupted=1
  if [ "$spinner" -eq 1 ] && [ "$spinner_scope" = "run" ]; then
    spinner_pause
    printf "\n" >&2
  fi
  echo "Interrupt received: will stop after current test (press Ctrl+C again to force abort)." >&2
  if [ "$spinner" -eq 1 ] && [ "$spinner_scope" = "run" ]; then
    spinner_resume
  fi
}
trap 'handle_sigint' INT TERM

run_with_timeout() {
  local secs="$1"; shift
  if command -v timeout >/dev/null 2>&1; then
    timeout "${secs}s" "$@"
  else
    "$@"
  fi
}

emit_record() {
  local test_name="$1"
  local status="$2"
  local err_total="$3"
  local err_assemble="$4"
  local err_compile="$5"
  local err_sim="$6"
  local err_diff="$7"
  local diff_ran="${8:-0}"
  local err_total_display="${9:-$err_total}"
  local err_sim_display="${10:-$err_sim}"
  local err_diff_display="${11:-$err_diff}"
  local vcheck_status="${WSRUN_VCHECK_STATUS:-$vcheck_status}"
  local err_vcheck="${WSRUN_VCHECK_ERRORS:-$vcheck_errors}"
  local diff_ran_json="false"
  if [ "$diff_ran" -eq 1 ]; then
    diff_ran_json="true"
  fi
  local json_line
  if [ "$spinner" -eq 1 ] && [ "$spinner_scope" = "run" ]; then
    spinner_pause
  fi
  json_line="$(printf '{"test":"%s","status":"%s","errors_total":%d,"errors_total_display":"%s","errors_assemble":%d,"errors_compile":%d,"errors_sim":%d,"errors_sim_display":"%s","errors_diff":%d,"errors_diff_display":"%s","errors_vcheck":%d,"vcheck_status":"%s","diff_ran":%s}' \
    "$test_name" "$status" "$err_total" "$err_total_display" "$err_assemble" "$err_compile" "$err_sim" "$err_sim_display" "$err_diff" "$err_diff_display" "$err_vcheck" "$vcheck_status" "$diff_ran_json")"
  printf "%s\n" "$json_line" >> "$summary_jsonl"
  case "$stream_mode" in
    json)
      printf "%s\n" "$json_line"
      ;;
    json_pretty)
      python3 - <<'PY' "$json_line"
import json,sys
print(json.dumps(json.loads(sys.argv[1]), indent=2))
PY
      ;;
    pretty)
      if [ "$status" = "PASS" ]; then
        echo "${line_prefix}[PASS] $test_name"
      else
        printf "%s[FAIL] %-${max_name_len}s%s| [ERRORS] total: %-7s asm: %-2s cmp: %-2s sim: %-2s diff: %-7s vcheck: %s\n" \
          "$line_prefix" "$test_name" "$pad" "$err_total_display" "$err_assemble" "$err_compile" "$err_sim_display" "$err_diff_display" "$vcheck_status"
      fi
      ;;
    none) ;;
  esac
  if [ "$spinner" -eq 1 ] && [ "$spinner_scope" = "run" ]; then
    spinner_resume
  fi
}

failures=0
fail_tests=0
pass_tests=0
index=0
index_offset="${WSRUN_INDEX_OFFSET:-0}"
fail_base="${WSRUN_FAIL_BASE:-0}"
spinner_label_prefix="${WSRUN_SPINNER_LABEL_PREFIX:-Running test suite}"
spinner_label_file=""
if [ -z "$index_offset" ]; then
  index_offset=0
fi
if [ -z "$fail_base" ]; then
  fail_base=0
fi
too_many_failures=0
if [ "$spinner" -eq 1 ] && [ "$spinner_scope" = "run" ]; then
  spinner_label="$spinner_label_prefix"
  if [ "$total_tests" -gt 0 ]; then
    spinner_label="${spinner_label_prefix} (${index_offset}/${total_tests}, failed: ${fail_base})"
  fi
  spinner_label_file="$(mktemp -t wsrun_spinner_label.XXXXXX 2>/dev/null || mktemp "/tmp/wsrun_spinner_label.XXXXXX")"
  if [ -n "$spinner_label_file" ]; then
    printf "%s" "$spinner_label" > "$spinner_label_file" 2>/dev/null || true
    SPINNER_LABEL_FILE="$spinner_label_file"
  fi
  if [ -n "${WSRUN_SPINNER_START_TS:-}" ]; then
    spinner_start "$spinner_label" "$WSRUN_SPINNER_START_TS"
  else
    spinner_start "$spinner_label"
  fi
fi

update_run_spinner_label() {
  if [ "$spinner" -eq 1 ] && [ "$spinner_scope" = "run" ] && [ "$total_tests" -gt 0 ]; then
    local fail_suffix=""
    if [ "$too_many_failures" -eq 1 ]; then
      fail_suffix="*"
    fi
    SPINNER_LABEL="${spinner_label_prefix} ($((index_offset + $1))/${total_tests}, failed: $((fail_base + fail_tests))${fail_suffix})"
    if [ -n "${spinner_label_file:-}" ]; then
      printf "%s" "$SPINNER_LABEL" > "$spinner_label_file" 2>/dev/null || true
    fi
  fi
}

run_vcheck() {
  local tmp
  local count
  local rc
  local -a vcheck_files=()
  case "$vcheck_phase" in
    phase_1)
      vcheck_files=(
        "$PROJECT_ROOT/demo1/verilog/fetch.v"
        "$PROJECT_ROOT/demo1/verilog/decode.v"
        "$PROJECT_ROOT/demo1/verilog/execute.v"
        "$PROJECT_ROOT/demo1/verilog/memory.v"
        "$PROJECT_ROOT/demo1/verilog/wb.v"
        "$PROJECT_ROOT/demo1/verilog/regFile.v"
        "$PROJECT_ROOT/demo1/verilog/proc.v"
      )
      ;;
    phase_2)
      vcheck_files=(
        # TODO: Add phase 2 student-editable files here.
      )
      ;;
    phase_3)
      vcheck_files=(
        # TODO: Add phase 3 student-editable files here.
      )
      ;;
    *)
      vcheck_files=()
      ;;
  esac
  if [ "${#vcheck_files[@]}" -eq 0 ]; then
    vcheck_status="Not Applicable"
    vcheck_errors=0
    return 0
  fi
  : > "$vcheck_log"
  vcheck_status="PASS"
  vcheck_errors=0
  for vf in "${vcheck_files[@]}"; do
    [ -f "$vf" ] || continue
    case "$vf" in
      *.v) ;;
      *) continue ;;
    esac
    tmp="$(mktemp)"
    rc=0
    if ! java -cp /repo/scripts/verilog_checker Vcheck "$vf" >"$tmp" 2>&1; then
      rc=1
    fi
    count="$(grep -c '^Line ' "$tmp" || true)"
    if [ "$count" -gt 0 ] || [ "$rc" -ne 0 ]; then
      vcheck_status="FAIL"
      if [ "$count" -eq 0 ]; then
        count=1
      fi
      vcheck_errors=$((vcheck_errors + count))
    fi
    {
      echo "== $vf =="
      cat "$tmp"
    } >> "$vcheck_log"
    rm -f "$tmp"
  done
}

run_vcheck

for prog in "${prog_list[@]}"; do
  if [ "$request_stop" -eq 1 ]; then
    break
  fi
  prog_trimmed="$(printf "%s" "$prog" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  [ -z "$prog_trimmed" ] && continue
  update_run_spinner_label "$((index + 1))"

  prog_host="$(normalize_prog_path "$prog_trimmed")"
  if [ ! -f "$prog_host" ]; then
    echo "[FAIL] $prog_trimmed: program not found" >&2
    failures=$((failures + 1))
    fail_tests=$((fail_tests + 1))
    [ "$failures" -gt "$max_failures" ] && break
    index=$((index + 1))
    continue
  fi
  prog_base="$(basename "$prog_host")"
  prog_name="${prog_base%.asm}"

  test_dir="$run_root/$prog_name"
  rm -rf "$test_dir"
  mkdir -p "$test_dir"

  if [ "$brief" -eq 0 ] && [ "$verbose" -eq 1 ]; then
    echo "============================================================"
    echo "[TEST] ($index) $prog_base"
    echo "[OUT]  $test_dir"
  fi

  err_assemble=0
  err_compile=0
  err_sim=0
  err_diff=0
  diff_ran=0
  err_total_display=""
  err_sim_display=""
  err_diff_display=""

  prog_repo="$(repo_path "$prog_host")"
  test_dir_repo="$(repo_path "$test_dir")"
  load_prefix_repo="$test_dir_repo/loadfile"

  if [ "$spinner" -eq 1 ] && [ "$spinner_scope" = "test" ]; then
    spinner_start "Running ${prog_base%.asm}"
  fi
  (cd "$test_dir" && "${ASSEMBLE_CMD[@]}" "$prog_repo" "$load_prefix_repo" > loadfile_all.img 2> assemble.log) || true
  asm_ok=0
  if [ -f "$test_dir/loadfile_all.img" ]; then
    asm_ok=1
  else
    err_assemble=1
    failures=$((failures + 1))
    if [ -f "$test_dir/assemble.log" ]; then
      [ "$verbose" -eq 1 ] && cat "$test_dir/assemble.log"
    fi
  fi

  # Compile (always attempt)
  cmp_ok=0
  if (cd "$test_dir" && "${IVERILOG_CMD[@]}" -g2012 -s "$tb_top" -o simv "${verilog_files_repo[@]}" > iverilog.log 2>&1); then
    cmp_ok=1
  else
    err_compile=1
    failures=$((failures + 1))
    [ "$verbose" -eq 1 ] && cat "$test_dir/iverilog.log"
  fi

  # If either asm or compile failed, mark sim/diff as N/A*
  if [ "$asm_ok" -eq 0 ] || [ "$cmp_ok" -eq 0 ]; then
    err_sim=-1
    err_diff=-1
    err_total=$((err_assemble + err_compile))
    err_total_display="${err_total}*"
    err_sim_display="N/A*"
    err_diff_display="N/A*"
    if [ "$spinner" -eq 1 ] && [ "$spinner_scope" = "test" ]; then
      spinner_stop
    fi
    emit_record "${prog_base%.asm}" "FAIL" "$err_total" "$err_assemble" "$err_compile" "$err_sim" "$err_diff" "$diff_ran" "$err_total_display" "$err_sim_display" "$err_diff_display"
    index=$((index + 1))
    if [ "$failures" -gt "$max_failures" ]; then
      break
    fi
    if [ "$request_stop" -eq 1 ]; then
      break
    fi
    continue
  fi

  # Run Verilog
  if ! (cd "$test_dir" && run_with_timeout "$sim_timeout_secs" "${VVP_CMD[@]}" simv > vvp.log 2>&1); then
    err_sim=1
    failures=$((failures + 1))
    [ "$verbose" -eq 1 ] && cat "$test_dir/vvp.log"
  fi

  if [ ! -f "$test_dir/verilogsim$trace_ext" ]; then
    err_sim=1
  fi

  # Run architectural simulator + diff
  sim_args=()
  if [ "$aligned" -eq 1 ]; then
    sim_args+=("-align")
  fi

  (cd "$test_dir" && "${SIMULATE_CMD[@]}" "${sim_args[@]}" "$test_dir_repo/loadfile_all.img" > archsim.out)

  status="FAILED"
  if [ "$err_sim" -eq 0 ] && [ -f "$test_dir/archsim$trace_ext" ] && [ -f "$test_dir/verilogsim$trace_ext" ]; then
    diff_ran=1
    if diff -q "$test_dir/archsim$trace_ext" "$test_dir/verilogsim$trace_ext" >/dev/null; then
      status="SUCCESS"
    fi
  fi

  if [ "$verbose" -eq 1 ] && [ "$diff_ran" -eq 1 ] && [ "$status" != "SUCCESS" ]; then
    echo "---- Diff summary ----"
    echo "[TRACE] archsim: $test_dir/archsim$trace_ext"
    echo "[TRACE] verilogsim: $test_dir/verilogsim$trace_ext"
    python3 - <<'PY' "$test_dir/archsim$trace_ext" "$test_dir/verilogsim$trace_ext"
import sys
a=open(sys.argv[1]).read().splitlines()
b=open(sys.argv[2]).read().splitlines()
n=max(len(a),len(b))
for i in range(n):
    la = a[i] if i < len(a) else ""
    lb = b[i] if i < len(b) else ""
    if la != lb:
        print(f"[MISMATCH] line {i+1}")
        print(f"  archsim : {la}")
        print(f"  verilog : {lb}")
        break
PY
    echo "----------------------"
  fi

  sim_cycles="$(grep -m1 -E 'SIMLOG:: sim_cycles' "$test_dir/verilogsim.log" | awk '{print $3}' || true)"
  inst_count="$(grep -m1 -E 'SIMLOG:: inst_count' "$test_dir/verilogsim.log" | awk '{print $3}' || true)"
  sim_cycles="${sim_cycles:-0}"
  inst_count="${inst_count:-0}"

  if [ "$status" = "SUCCESS" ]; then
    err_total=0
    err_diff=0
    err_total_display="$err_total"
    err_sim_display="$err_sim"
    err_diff_display="$err_diff"
    if [ "$spinner" -eq 1 ] && [ "$spinner_scope" = "test" ]; then
      spinner_stop
    fi
    pass_tests=$((pass_tests + 1))
    emit_record "${prog_base%.asm}" "PASS" "$err_total" "$err_assemble" "$err_compile" "$err_sim" "$err_diff" "$diff_ran" "$err_total_display" "$err_sim_display" "$err_diff_display"
  else
    if [ "$diff_ran" -eq 1 ]; then
      diff_count="$(python3 - <<'PY' "$test_dir/archsim$trace_ext" "$test_dir/verilogsim$trace_ext"
import sys
a=open(sys.argv[1]).read().splitlines()
b=open(sys.argv[2]).read().splitlines()
n=max(len(a),len(b))
cnt=0
for i in range(n):
    la = a[i] if i < len(a) else ""
    lb = b[i] if i < len(b) else ""
    if la != lb:
        cnt += 1
print(cnt)
PY
)"
      err_diff="${diff_count}"
      err_diff_display="$err_diff"
    else
      err_diff=-1
      err_diff_display="N/A*"
    fi
    failures=$((failures + 1))
    err_total=$((err_assemble + err_compile + err_sim))
    if [ "$diff_ran" -eq 1 ]; then
      err_total=$((err_total + err_diff))
      err_total_display="$err_total"
    else
      err_total_display="${err_total}*"
    fi
    if [ "$spinner" -eq 1 ] && [ "$spinner_scope" = "test" ]; then
      spinner_stop
    fi
    err_sim_display="$err_sim"
    fail_tests=$((fail_tests + 1))
    emit_record "${prog_base%.asm}" "FAIL" "$err_total" "$err_assemble" "$err_compile" "$err_sim" "$err_diff" "$diff_ran" "$err_total_display" "$err_sim_display" "$err_diff_display"
  fi
  if [ "$request_stop" -eq 1 ]; then
    break
  fi

  if [ "$failures" -gt "$max_failures" ]; then
    echo "Too many failures...stopping early"
    too_many_failures=1
    update_run_spinner_label "$index"
    break
  fi

  index=$((index + 1))
  rm -f "$test_dir/simv"

done
if [ "$request_stop" -eq 1 ]; then
  if [ "$spinner" -eq 1 ] && [ "$spinner_scope" = "run" ]; then
    spinner_pause
    printf "\n" >&2
  fi
  echo "Interrupted: finishing current test and stopping." >&2
  if [ "$spinner" -eq 1 ]; then
    spinner_stop_quiet || true
  fi
  exit 130
fi
if [ "$spinner" -eq 1 ] && [ "$spinner_scope" = "run" ]; then
  spinner_stop_quiet
fi

if [ "$brief" -eq 0 ] && [ "$stream_mode" = "none" ]; then
  echo "Summary json: $summary_jsonl"
fi
