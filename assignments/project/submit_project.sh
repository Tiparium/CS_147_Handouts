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
  *)
    echo "[submit] Unsupported project phase: $PROJECT_PHASE_RAW" >&2
    echo "[submit] Currently supported: phase_1" >&2
    exit 1
    ;;
esac

if [ "$PROJECT_PHASE" != "phase_1" ]; then
  echo "[submit] Only phase_1 submission flow is implemented right now." >&2
  exit 1
fi

REPORT_LOG="$ASSIGNMENT_DIR/submission_report.log"
REPORT_VERBOSE="$ASSIGNMENT_DIR/submission_report_verbose.log"
SUMMARY_JSON="$ASSIGNMENT_DIR/project_phase_1_grade_summary.json"
MARKER="$ASSIGNMENT_DIR/.last_submit_zip"
TURNIN_DIR="$TURNINS_ROOT/project_phase_1"
SUB_BASENAME="project_phase_1_${STUDENT_NAME}_submission"

mkdir -p "$ASSIGNMENT_DIR"

set +e
(
  cd "$ASSIGNMENTS_ROOT"
  bash -lc "set -o pipefail; ./.testing/test_runner.sh project phase_1 | tee \"$REPORT_LOG\""
)
test_rc=$?
set -e
if [ "$test_rc" -ne 0 ]; then
  echo "[submit] NOTE: Tests reported failures (rc=$test_rc). See assignments/project/submission_report.log." >&2
fi

set +e
(
  cd "$ASSIGNMENTS_ROOT"
  bash -lc "set -o pipefail; ./.testing/test_runner.sh -v project phase_1 > \"$REPORT_VERBOSE\""
)
set -e

echo "[submit] computing project phase_1 summary..."
python3 - <<'PY' "$ASSIGNMENT_DIR" "$SUMMARY_JSON" "$ASSIGNMENTS_ROOT/project/.wsrun_out/phase_1/summary_all.jsonl"
import json
import pathlib
import sys

assignment_dir = pathlib.Path(sys.argv[1])
out_path = pathlib.Path(sys.argv[2])
summary_path = pathlib.Path(sys.argv[3])
project_root = assignment_dir
public_root = project_root / "testprograms" / "public"
student_list = project_root / "testprograms" / "student_custom" / "all.list"


def read_list(path: pathlib.Path) -> set[str]:
    out = set()
    if not path.exists():
        return out
    for raw in path.read_text(errors="ignore").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        name = pathlib.Path(line).name
        if name.endswith(".asm"):
            name = name[:-4]
        out.add(name)
    return out

supplied_lists = ["inst_tests", "complex_demo1", "rand_simple", "rand_complex", "rand_ctrl", "rand_mem"]
supplied_tests = set()
test_group_map = {}
for d in supplied_lists:
    listed = read_list(public_root / d / "all.list")
    supplied_tests |= listed
    for t in listed:
        test_group_map[t] = d
student_tests = read_list(student_list)

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
        status = str(obj.get("status", "FAIL")).upper()
        category = "supplied"
        group = test_group_map.get(name)
        if name in student_tests:
            category = "student_custom"
            group = "student_custom"
        elif name in supplied_tests:
            category = "supplied"
        elif name.startswith("t_"):
            category = "supplied"
            if group is None:
                group = "rand"
        if group is None:
            group = "unknown"
        results.append({"test": name, "status": status, "category": category, "group": group})

supplied_total = sum(1 for r in results if r["category"] == "supplied")
supplied_pass = sum(1 for r in results if r["category"] == "supplied" and r["status"] == "PASS")
supplied_fail = supplied_total - supplied_pass
student_total = sum(1 for r in results if r["category"] == "student_custom")
student_pass = sum(1 for r in results if r["category"] == "student_custom" and r["status"] == "PASS")
student_fail = student_total - student_pass

raw_percent = 0.0
if supplied_total > 0:
    raw_percent = (supplied_pass / supplied_total) * 100.0

payload = {
    "phase": "phase_1",
    "scoring": "supplied_only",
    "supplied": {"tests": supplied_total, "passed": supplied_pass, "failed": supplied_fail},
    "student_custom": {"tests": student_total, "passed": student_pass, "failed": student_fail},
    "raw_percent": round(raw_percent, 2),
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
  files="$(find demo1/verilog common/verilog -type f \( -name '*.v' -o -name '*.sv' -o -name '*.vh' \) -print 2>/dev/null || true)"
  if [ -n "$files" ]; then
    printf "%s\n" "$files" | LC_ALL=C sort | xargs sha256sum
  fi
  if [ -f "project_phase_1_grade_summary.json" ]; then
    sha256sum "project_phase_1_grade_summary.json"
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
  marker_rel="generated_turnins/project_phase_1/$name"
  echo "[submit] creating submission archive: $name"
fi

stage_dir="$(mktemp -d)"
mkdir -p "$stage_dir/demo1" "$stage_dir/common"
cp -R "$ASSIGNMENT_DIR/demo1/verilog" "$stage_dir/demo1/"
if [ -d "$ASSIGNMENT_DIR/common/verilog" ]; then
  cp -R "$ASSIGNMENT_DIR/common/verilog" "$stage_dir/common/"
fi
cp "$REPORT_LOG" "$stage_dir/submission_report.log"
cp "$REPORT_VERBOSE" "$stage_dir/submission_report_verbose.log"
cp "$SUMMARY_JSON" "$stage_dir/project_phase_1_grade_summary.json"
(cd "$stage_dir" && zip -rq "$zip_path" .)
rm -rf "$stage_dir"

echo "$marker_rel" > "$MARKER"
if [ -d "$ASSIGNMENT_DIR/demo1/Gradescope_Autograder_Template/test_submissions" ]; then
  if cp "$zip_path" "$ASSIGNMENT_DIR/demo1/Gradescope_Autograder_Template/test_submissions/$name"; then
    echo "[submit] grader copy ready at demo1/Gradescope_Autograder_Template/test_submissions/$name"
  else
    echo "[submit] warning: could not copy zip into demo1/Gradescope_Autograder_Template/test_submissions; using $marker_rel instead."
  fi
else
  echo "[submit] demo1/Gradescope_Autograder_Template/test_submissions not found; skipping grader copy." >&2
fi

rm -f "$REPORT_LOG" "$REPORT_VERBOSE" "$SUMMARY_JSON"

exit 0
