#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
from typing import Dict, List, Optional, Tuple

VERBOSE = os.environ.get("AG_VERBOSE", os.environ.get("VERBOSE", "0")) not in ("0", "", "false", "False", None)
HASH_VERBOSE = os.environ.get("AG_HASH_VERBOSE", "0") not in ("0", "", "false", "False", None)

CONFIG = {
    "phase": "phase_2",
    "summary_name": "project_phase_2_grade_summary.json",
    "assignment_name": "project_phase_2",
    "total_points": 800.0,
    "required_student_tests": 2,
    "mode": "count_remap",
    "baseline_points": 800.0,
    "specialized_points": 0.0,
    "student_custom_points": 0.0,
}

TOTAL_POINTS = float(os.environ.get("TOTAL_POINTS", CONFIG.get("total_points", 100.0)))
REQUIRED_STUDENT_TESTS = int(CONFIG.get("required_student_tests", 2))
SUMMARY_NAME = str(CONFIG.get("summary_name", "project_phase_2_grade_summary.json"))
MODE = str(CONFIG.get("mode", "count_remap"))


def clamp(value: float, low: float = 0.0, high: float = 100.0) -> float:
    return max(low, min(high, value))


def parse_hash_block(report_path: Path) -> Dict[str, str]:
    hashes: Dict[str, str] = {}
    if not report_path.exists():
        return hashes
    with report_path.open() as f:
        for line in f:
            stripped = line.strip()
            if not stripped:
                continue
            parts = stripped.split(None, 1)
            if len(parts) == 2 and all(c in "0123456789abcdef" for c in parts[0].lower()):
                digest, path = parts
                hashes[path.strip().lstrip("./")] = digest
            else:
                break
    return hashes


def _hash_report_body(report_path: Path) -> Optional[str]:
    if not report_path.exists():
        return None
    data = report_path.read_text(errors="ignore")
    lines = data.splitlines(keepends=True)
    body_lines = []
    in_hash = True
    for line in lines:
        stripped = line.strip()
        if in_hash:
            if not stripped:
                continue
            parts = stripped.split(None, 1)
            if len(parts) == 2 and all(c in "0123456789abcdef" for c in parts[0].lower()):
                continue
            in_hash = False
        body_lines.append(line)
    body = "".join(body_lines)
    return hashlib.sha256(body.encode("utf-8")).hexdigest()


def recompute_hashes(submission_root: Path) -> Dict[str, str]:
    out: Dict[str, str] = {}
    for path in sorted(submission_root.rglob("*.v")) + sorted(submission_root.rglob("*.sv")) + sorted(submission_root.rglob("*.vh")):
        rel = str(path.relative_to(submission_root)).lstrip("./")
        with path.open("rb") as f:
            out[rel] = hashlib.sha256(f.read()).hexdigest()
    summary = submission_root / SUMMARY_NAME
    if summary.exists():
        out[str(summary.relative_to(submission_root))] = hashlib.sha256(summary.read_bytes()).hexdigest()
    report_hash = _hash_report_body(submission_root / "submission_report.log")
    if report_hash:
        out["submission_report.log"] = report_hash
    return out


def recompute_expected_hashes(submission_root: Path, expected_paths: List[str]) -> Dict[str, str]:
    out: Dict[str, str] = {}
    for rel in sorted(expected_paths):
        if rel == "submission_report.log":
            continue
        p = (submission_root / rel).resolve()
        try:
            if not p.exists() or p.is_dir():
                out[rel] = "__MISSING__"
                continue
            with p.open("rb") as f:
                out[rel] = hashlib.sha256(f.read()).hexdigest()
        except Exception:
            out[rel] = "__ERROR__"
    return out


def hash_report(title: str, mapping: Dict[str, str]) -> List[str]:
    rep: List[str] = []
    rep.append(f"================ {title} ================")
    if not mapping:
        rep.append("(no entries)")
    else:
        for path in sorted(mapping.keys()):
            rep.append(f"{path}: {mapping[path]}")
    rep.append("=" * len(rep[0]))
    return rep


def ratio(passed: int, total: int) -> float:
    if total <= 0:
        return 0.0
    return float(passed) / float(total)


def compute_phase_scores(summary: Dict) -> Tuple[float, float, List[str]]:
    notes: List[str] = []
    buckets = summary.get("buckets", {})
    student = summary.get("student_custom", buckets.get("student_custom", {}))
    baseline = buckets.get("baseline", {})
    specialized = buckets.get("specialized", {})

    student_total = int(student.get("tests", 0))
    student_pass = int(student.get("passed", 0))
    student_required = int(student.get("required", REQUIRED_STUDENT_TESTS))
    student_required_pass = int(student.get("required_passing", min(student_required, student_pass)))

    baseline_total = int(baseline.get("tests", 0))
    baseline_pass = int(baseline.get("passed", 0))
    specialized_total = int(specialized.get("tests", 0))
    specialized_pass = int(specialized.get("passed", 0))

    final_points = 0.0
    if MODE == "count_remap":
        raw_total = baseline_total + student_required
        raw_earned = baseline_pass + student_required_pass
        raw_percent = 100.0 * ratio(raw_earned, raw_total)
        final_points = TOTAL_POINTS * ratio(raw_earned, raw_total)
        notes.append("Scoring policy: Phase 2 baseline count/remap")
        notes.append(f"Baseline tests: {baseline_pass}/{baseline_total} passed")
        notes.append(f"Student custom requirement: {student_required_pass}/{student_required} satisfied")
        notes.append(f"Raw counted passes: {raw_earned}/{raw_total}")
        return raw_percent, final_points, notes

    baseline_points = float(CONFIG.get("baseline_points", 0.0))
    specialized_points = float(CONFIG.get("specialized_points", 0.0))
    student_points = float(CONFIG.get("student_custom_points", 0.0))

    if MODE == "weighted_buckets":
        baseline_score = baseline_points * ratio(baseline_pass, baseline_total)
        specialized_score = specialized_points * ratio(specialized_pass, specialized_total)
        student_score = student_points * ratio(student_required_pass, student_required)
        final_points = baseline_score + specialized_score + student_score
        raw_percent = 100.0 * ratio(final_points, TOTAL_POINTS)
        notes.append("Scoring policy: weighted buckets")
        notes.append(f"Baseline bucket: {baseline_pass}/{baseline_total} -> {baseline_score:.2f}/{baseline_points:.2f}")
        notes.append(f"Specialized bucket: {specialized_pass}/{specialized_total} -> {specialized_score:.2f}/{specialized_points:.2f}")
        notes.append(f"Student custom bucket: {student_required_pass}/{student_required} -> {student_score:.2f}/{student_points:.2f}")
        return raw_percent, final_points, notes

    if MODE == "pass_fail":
        passed = (
            baseline_total > 0 and baseline_pass == baseline_total and
            specialized_total > 0 and specialized_pass == specialized_total and
            student_required_pass >= student_required
        )
        final_points = TOTAL_POINTS if passed else 0.0
        raw_percent = 100.0 if passed else 0.0
        notes.append("Scoring policy: optional pass/fail")
        notes.append(
            "Completion status: "
            + ("PASS" if passed else "FAIL")
        )
        notes.append(f"Baseline tests: {baseline_pass}/{baseline_total} passed")
        notes.append(f"Specialized tests: {specialized_pass}/{specialized_total} passed")
        notes.append(f"Student custom requirement: {student_required_pass}/{student_required} satisfied")
        return raw_percent, final_points, notes

    raise ValueError(f"Unknown grading mode: {MODE}")


def run_assignment_tests(submission_root: Path) -> Tuple[float, float, List[str]]:
    notes: List[str] = []
    report = submission_root / "submission_report.log"
    expected_hashes = parse_hash_block(report)
    hash_status = "MISSING"
    if expected_hashes:
        expected_files = {k: v for k, v in expected_hashes.items() if k != "submission_report.log"}
        expected_report = expected_hashes.get("submission_report.log")
        actual_files = recompute_expected_hashes(submission_root, list(expected_files.keys()))
        source_mismatch = expected_files != actual_files
        report_mismatch = False
        if expected_report is not None:
            actual_report = _hash_report_body(report)
            report_mismatch = (actual_report != expected_report)
        if source_mismatch:
            hash_status = "MISMATCH"
            notes.append("Hash mismatch between expected and actual submission files (scoring forced to 0).")
            if VERBOSE or HASH_VERBOSE:
                notes.extend(hash_report("HASH REPORT (expected source)", expected_files))
                notes.extend(hash_report("HASH REPORT (actual source)", actual_files))
            notes.insert(0, f"Hash status: {hash_status}")
            return 0.0, 0.0, notes
        hash_status = "REPORT_MISMATCH" if report_mismatch else "OK"
        if report_mismatch:
            notes.append("submission_report.log hash mismatch detected (non-fatal).")

    summary_path = submission_root / SUMMARY_NAME
    if not summary_path.exists():
        notes.insert(0, f"Hash status: {hash_status}")
        notes.append(f"{SUMMARY_NAME} not found.")
        return 0.0, 0.0, notes
    try:
        summary = json.loads(summary_path.read_text(errors="ignore"))
    except json.JSONDecodeError:
        notes.insert(0, f"Hash status: {hash_status}")
        notes.append(f"{SUMMARY_NAME} is invalid JSON.")
        return 0.0, 0.0, notes

    raw_percent, final_points, phase_notes = compute_phase_scores(summary)
    notes.insert(0, f"Hash status: {hash_status}")
    notes.extend(phase_notes)
    return clamp(raw_percent), round(final_points, 2), notes


def main() -> int:
    submission_root = Path.cwd()
    raw_percent, final_score, notes = run_assignment_tests(submission_root)
    curved_percent = raw_percent

    print("=== Grading Summary ===")
    print(f"Total points: {TOTAL_POINTS:.2f}")
    print(f"Raw percent : {raw_percent:.2f}%")
    print(f"Curved pct  : {curved_percent:.2f}%")
    print(f"Final score : {final_score:.2f} / {TOTAL_POINTS:.2f}")
    print("autograder_messages=[]")
    print("-----------------------")
    for note in notes:
        print(note)

    print(f"raw_score= {raw_percent:.2f}")
    print(f"curved_percent= {curved_percent:.2f}")
    print(f"final_score= {final_score:.2f}")
    print("timing_flag=no_curve")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
