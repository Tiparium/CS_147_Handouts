#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ASSIGNMENTS_ROOT="${ASSIGNMENTS_ROOT:-$REPO_ROOT/assignments}"
ASSIGNMENT_DIR="${ASSIGNMENT_DIR:-$ASSIGNMENTS_ROOT/project}"
TURNINS_ROOT="${TURNINS_ROOT:-$REPO_ROOT/generated_turnins}"
STUDENT_NAME="${STUDENT_NAME:-unknown_student}"
PROJECT_PHASE_RAW="${PROJECT_PHASE:-phase_1}"
JUSTGRADE="${JUSTGRADE:-0}"

case "$PROJECT_PHASE_RAW" in
  phase1|phase_1|1) PROJECT_PHASE="phase_1" ;;
  phase2|phase_2|2) PROJECT_PHASE="phase_2" ;;
  phase2_1|phase_2_1|2_1) PROJECT_PHASE="phase_2_1" ;;
  phase2_2|phase_2_2|2_2) PROJECT_PHASE="phase_2_2" ;;
  phase2_3|phase_2_3|2_3) PROJECT_PHASE="phase_2_3" ;;
  phase3|phase_3|3) PROJECT_PHASE="phase_3" ;;
  *)
    echo "[submit] Unsupported project phase: $PROJECT_PHASE_RAW" >&2
    echo "[submit] Supported: phase_1, phase_2, phase_2_1, phase_2_2, phase_2_3, phase_3" >&2
    exit 1
    ;;
esac

case "$PROJECT_PHASE" in
  phase_1)
    demo_name="demo1"
    summary_name="project_phase_1_grade_summary.json"
    turnin_slug="project_phase_1"
    grader_copy_dir="$ASSIGNMENT_DIR/demo1/Gradescope_Autograder_Template/test_submissions"
    ;;
  phase_2|phase_2_1|phase_2_2|phase_2_3)
    demo_name="demo2"
    summary_name="project_${PROJECT_PHASE}_grade_summary.json"
    turnin_slug="project_${PROJECT_PHASE}"
    grader_copy_dir="$ASSIGNMENT_DIR/demo2/Autograders/Gradescope_Autograder_Template_${PROJECT_PHASE}/test_submissions"
    ;;
  phase_3)
    demo_name="demo3"
    summary_name="project_phase_3_grade_summary.json"
    turnin_slug="project_phase_3"
    grader_copy_dir="$ASSIGNMENT_DIR/demo3/Gradescope_Autograder_Template/test_submissions"
    ;;
esac

REPORT_LOG="$ASSIGNMENT_DIR/submission_report.log"
REPORT_VERBOSE="$ASSIGNMENT_DIR/submission_report_verbose.log"
REPORT_LOG_TMP="$ASSIGNMENT_DIR/.submission_report.log.tmp"
REPORT_VERBOSE_TMP="$ASSIGNMENT_DIR/.submission_report_verbose.log.tmp"
SUMMARY_JSON="$ASSIGNMENT_DIR/$summary_name"
MARKER="$ASSIGNMENT_DIR/.last_submit_zip"
TURNIN_DIR="$TURNINS_ROOT/$turnin_slug"
SUB_BASENAME="${turnin_slug}_${STUDENT_NAME}_submission"

mkdir -p "$ASSIGNMENT_DIR"
rm -f "$REPORT_LOG" "$REPORT_VERBOSE" "$REPORT_LOG_TMP" "$REPORT_VERBOSE_TMP"

set +e
(
  cd "$ASSIGNMENTS_ROOT"
  bash -lc "set -o pipefail; PROJECT_AUTOGRADER_PENDING=1 ./.testing/test_runner.sh project $PROJECT_PHASE | tee \"$REPORT_LOG_TMP\""
)
test_rc=$?
set -e
if [ -f "$REPORT_LOG_TMP" ]; then
  mv -f "$REPORT_LOG_TMP" "$REPORT_LOG"
fi
if [ ! -f "$REPORT_LOG" ]; then
  echo "[submit] Quiet submission report was not generated: $REPORT_LOG" >&2
  exit 1
fi
if [ "$test_rc" -ne 0 ]; then
  echo "[submit] NOTE: Tests reported failures (rc=$test_rc). See assignments/project/submission_report.log." >&2
fi

set +e
(
  cd "$ASSIGNMENTS_ROOT"
  bash -lc "set -o pipefail; ./.testing/test_runner.sh -v project $PROJECT_PHASE > \"$REPORT_VERBOSE_TMP\""
)
set -e
if [ -f "$REPORT_VERBOSE_TMP" ]; then
  mv -f "$REPORT_VERBOSE_TMP" "$REPORT_VERBOSE"
fi

echo "[submit] computing $PROJECT_PHASE summary..."
python3 - <<'PY' "$ASSIGNMENT_DIR" "$SUMMARY_JSON" "$ASSIGNMENTS_ROOT/project/.wsrun_out/$PROJECT_PHASE/summary_all.jsonl" "$PROJECT_PHASE"
import json
import pathlib
import sys
from typing import Dict, Iterable, List, Set, Tuple

assignment_dir = pathlib.Path(sys.argv[1])
out_path = pathlib.Path(sys.argv[2])
summary_path = pathlib.Path(sys.argv[3])
phase = sys.argv[4]
project_root = assignment_dir
public_root = project_root / "testprograms" / "public"
student_root = project_root / "testprograms" / "student_custom"


def read_list(path: pathlib.Path) -> List[str]:
    out: List[str] = []
    if not path.exists():
        return out
    for raw in path.read_text(errors="ignore").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        name = pathlib.Path(line).name
        if name.endswith(".asm"):
            name = name[:-4]
        out.append(name)
    return out


def read_set(path: pathlib.Path) -> Set[str]:
    return set(read_list(path))


def normalized_status(obj: Dict) -> str:
    return str(obj.get("status", "FAIL")).upper()


def dedupe_key(obj: Dict) -> Tuple[str, str, str, str, str]:
    return (
        str(obj.get("test", "")).strip(),
        str(obj.get("group", "")).strip(),
        str(obj.get("bucket", "")).strip(),
        str(obj.get("implementation", "")).strip(),
        str(obj.get("bench", "")).strip(),
    )


def summarize_bucket(results: Iterable[Dict]) -> Dict[str, int]:
    items = list(results)
    total = len(items)
    passed = sum(1 for r in items if normalized_status(r) == "PASS")
    return {"tests": total, "passed": passed, "failed": total - passed}


if phase == "phase_1":
    supplied_lists = ["inst_tests", "complex_demo1", "rand_simple", "rand_complex", "rand_ctrl", "rand_mem"]
    supplied_tests: Set[str] = set()
    test_group_map: Dict[str, str] = {}
    for d in supplied_lists:
        listed = read_set(public_root / d / "all.list")
        supplied_tests |= listed
        for t in listed:
            test_group_map[t] = d
    student_tests = read_set(student_root / "all_phase_1.list")

    results = []
    if summary_path.exists():
        for raw in summary_path.read_text(errors="ignore").splitlines():
            line = raw.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue
            name = str(obj.get("test", "")).strip()
            if not name:
                continue
            status = normalized_status(obj)
            category = str(obj.get("category", "")).strip() or "supplied"
            group = str(obj.get("group", "")).strip() or test_group_map.get(name, "unknown")
            if name in student_tests:
                category = "student_custom"
                group = "student_custom"
            elif name in supplied_tests:
                category = "supplied"
            elif name.startswith("t_"):
                category = "supplied"
                if group == "unknown":
                    group = "rand"
            results.append({"test": name, "status": status, "category": category, "group": group})

    supplied = summarize_bucket(r for r in results if r["category"] == "supplied")
    student = summarize_bucket(r for r in results if r["category"] == "student_custom")
    raw_percent = 0.0
    if supplied["tests"] > 0:
        raw_percent = (supplied["passed"] / supplied["tests"]) * 100.0
    payload = {
        "phase": "phase_1",
        "scoring": "supplied_only",
        "supplied": supplied,
        "student_custom": student,
        "raw_percent": round(raw_percent, 2),
        "tests": results,
    }
    out_path.write_text(json.dumps(payload, indent=2))
    print(f"[submit] wrote summary: {out_path}")
    raise SystemExit(0)


student_tests = read_set(student_root / "all_phase_2.list")
baseline_dirs = ["inst_tests", "complex_demo1", "rand_simple", "rand_complex", "rand_ctrl", "rand_mem", "complex_demo2"]
phase3_dirs = ["perf", "complex_demofinal", "rand_final", "rand_ldst", "rand_idcache", "rand_icache", "rand_dcache", "complex_demo1", "complex_demo2", "rand_complex", "rand_ctrl", "inst_tests"]
baseline_tests: Set[str] = set()
for d in baseline_dirs:
    baseline_tests |= read_set(public_root / d / "all.list")

specialized_tests: Set[str] = set()
specialized_groups: Set[str] = set()
if phase == "phase_2_1":
    specialized_tests |= read_set(public_root / "inst_tests" / "unaligned" / "all.list")
    specialized_groups.add("inst_tests_unaligned")
elif phase == "phase_2_2":
    specialized_tests |= read_set(public_root / "complex_demo2" / "all.list")
    specialized_groups.add("complex_demo2_stall")
elif phase == "phase_2_3":
    specialized_groups |= {"direct_perfbench", "direct_randbench", "associative_perfbench", "associative_randbench"}

if phase == "phase_3":
    student_tests = read_set(student_root / "all_phase_3.list")
    baseline_tests = set()
    for d in phase3_dirs:
        baseline_tests |= read_set(public_root / d / "all.list")

results: List[Dict] = []
seen: Set[Tuple[str, str, str, str, str]] = set()
if summary_path.exists():
    for raw in summary_path.read_text(errors="ignore").splitlines():
        line = raw.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
        except json.JSONDecodeError:
            continue
        name = str(obj.get("test", "")).strip()
        if not name:
            continue
        key = dedupe_key(obj)
        if key in seen:
            continue
        seen.add(key)
        status = normalized_status(obj)
        category = str(obj.get("category", "")).strip()
        group = str(obj.get("group", "")).strip()
        bucket = str(obj.get("bucket", "")).strip()
        if not category:
            category = "student_custom" if group == "student_custom" or name in student_tests else "supplied"
        if not group and category == "student_custom":
            group = "student_custom"
        if not bucket:
            if category == "student_custom" or name in student_tests:
                bucket = "student_custom"
            elif group in specialized_groups or name in specialized_tests:
                bucket = "specialized"
            else:
                bucket = "baseline"
        group_label = str(obj.get("group_label", "")).strip()
        if not group_label:
            group_label = group
        result = dict(obj)
        result.update({
            "test": name,
            "status": status,
            "category": category,
            "group": group,
            "group_label": group_label,
            "bucket": bucket,
        })
        results.append(result)

student_results = [r for r in results if r["bucket"] == "student_custom"]
specialized_results = [r for r in results if r["bucket"] == "specialized"]
baseline_results = [r for r in results if r["bucket"] == "baseline"]

required_student_tests = 2
student_bucket = summarize_bucket(student_results)
specialized_bucket = summarize_bucket(specialized_results)
baseline_bucket = summarize_bucket(baseline_results)

payload = {
    "phase": phase,
    "required_student_tests": required_student_tests,
    "student_custom": {
        **student_bucket,
        "required": required_student_tests,
        "required_passing": min(required_student_tests, student_bucket["passed"]),
    },
    "buckets": {
        "student_custom": student_bucket,
        "specialized": specialized_bucket,
        "baseline": baseline_bucket,
    },
    "tests": results,
}
out_path.write_text(json.dumps(payload, indent=2))
print(f"[submit] wrote summary: {out_path}")
PY

echo "[submit] computing hashes..."
report_body="$ASSIGNMENT_DIR/submission_report.body.log"
cp "$REPORT_LOG" "$report_body"
(
  cd "$ASSIGNMENT_DIR"
  files="$(find "$demo_name/verilog" common/verilog -type f \( -name '*.v' -o -name '*.sv' -o -name '*.vh' \) -print 2>/dev/null || true)"
  if [ -n "$files" ]; then
    printf "%s\n" "$files" | LC_ALL=C sort | xargs sha256sum
  fi
  if [ -f "$summary_name" ]; then
    sha256sum "$summary_name"
  fi
  report_hash="$(sha256sum "$report_body" | awk '{print $1}')"
  echo "$report_hash  submission_report.log"
) >"$ASSIGNMENT_DIR/hashes.tmp"
rm -f "$report_body"

cat "$ASSIGNMENT_DIR/hashes.tmp" "$REPORT_LOG" >"$ASSIGNMENT_DIR/submission_report.log.tmp"
mv "$ASSIGNMENT_DIR/submission_report.log.tmp" "$REPORT_LOG"
rm -f "$ASSIGNMENT_DIR/hashes.tmp"

zip_path=""
name=""
marker_rel=""
if [ "$JUSTGRADE" = "1" ]; then
  zip_path="$ASSIGNMENT_DIR/grade_tmp_submission.zip"
  name="${zip_path##*/}"
  marker_rel="assignments/project/$name"
  echo "[submit] creating temp grader archive: $name"
else
  mkdir -p "$TURNIN_DIR"
  i=1
  while [ -e "$TURNIN_DIR/${SUB_BASENAME}${i}.zip" ]; do
    i=$((i + 1))
  done
  name="${SUB_BASENAME}${i}.zip"
  zip_path="$TURNIN_DIR/$name"
  marker_rel="generated_turnins/$turnin_slug/$name"
  echo "[submit] creating submission archive: $name"
fi

stage_dir="$(mktemp -d)"
mkdir -p "$stage_dir/$demo_name" "$stage_dir/common"
if [ -d "$ASSIGNMENT_DIR/$demo_name/verilog" ]; then
  cp -R "$ASSIGNMENT_DIR/$demo_name/verilog" "$stage_dir/$demo_name/"
fi
if [ -d "$ASSIGNMENT_DIR/$demo_name/writeup" ]; then
  cp -R "$ASSIGNMENT_DIR/$demo_name/writeup" "$stage_dir/$demo_name/"
fi
if [ -d "$ASSIGNMENT_DIR/common/verilog" ]; then
  cp -R "$ASSIGNMENT_DIR/common/verilog" "$stage_dir/common/"
fi
cp "$REPORT_LOG" "$stage_dir/submission_report.log"
cp "$REPORT_VERBOSE" "$stage_dir/submission_report_verbose.log"
cp "$SUMMARY_JSON" "$stage_dir/$summary_name"
(cd "$stage_dir" && zip -rq "$zip_path" .)
rm -rf "$stage_dir"

echo "$marker_rel" > "$MARKER"
if [ -d "$grader_copy_dir" ]; then
  if cp "$zip_path" "$grader_copy_dir/$name"; then
    echo "[submit] grader copy ready at ${grader_copy_dir#$ASSIGNMENT_DIR/}/$name"
  else
    echo "[submit] warning: could not copy zip into grader test_submissions; using $marker_rel instead."
  fi
else
  echo "[submit] grader test_submissions directory not found; skipping grader copy." >&2
fi

rm -f "$REPORT_LOG" "$REPORT_VERBOSE" "$SUMMARY_JSON"

exit 0
