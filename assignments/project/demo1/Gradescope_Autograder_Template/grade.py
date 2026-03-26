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
    "total_points": 400.0,
    "clamp_low": 0.0,
    "clamp_high": 100.0,
    "phase_1_offset_points": 1.0,
}

TOTAL_POINTS = float(os.environ.get("TOTAL_POINTS", CONFIG.get("total_points", 100.0)))
C_L = float(CONFIG.get("clamp_low", 0.0))
C_H = float(CONFIG.get("clamp_high", 100.0))
PHASE_1_OFFSET_POINTS = float(CONFIG.get("phase_1_offset_points", 0.0))
PHASE_1_EXTRA_CREDIT_TESTS = {"siic_0"}


def clamp(value: float, low: float = C_L, high: float = C_H) -> float:
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
    summary = submission_root / "project_phase_1_grade_summary.json"
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


def normalize_group(group: str) -> str:
    if group.startswith("rand_") or group == "rand":
        return "rand"
    return group


def is_phase_1_extra_credit_test(name: str) -> bool:
    return name in PHASE_1_EXTRA_CREDIT_TESTS


def run_assignment_tests(submission_root: Path) -> Tuple[float, float, float, List[str], List[Dict]]:
    notes: List[str] = []
    tests: List[Dict] = []

    report = submission_root / "submission_report.log"
    expected_hashes = parse_hash_block(report)
    actual_hashes = recompute_hashes(submission_root)

    hash_status = "MISSING"
    if expected_hashes:
        expected_files = {k: v for k, v in expected_hashes.items() if k != "submission_report.log"}
        expected_report = expected_hashes.get("submission_report.log")
        actual_files = recompute_expected_hashes(submission_root, list(expected_files.keys()))

        source_mismatch = expected_files != actual_files
        report_mismatch = False
        if expected_report is not None:
            actual_report = _hash_report_body(submission_root / "submission_report.log")
            report_mismatch = (actual_report != expected_report)

        if source_mismatch:
            hash_status = "MISMATCH"
            notes.append("Hash mismatch between expected and actual submission files (scoring forced to 0).")
            if VERBOSE or HASH_VERBOSE:
                notes.extend(hash_report("HASH REPORT (expected source)", expected_files))
                notes.extend(hash_report("HASH REPORT (actual source)", actual_files))
            notes.insert(0, f"Hash status: {hash_status}")
            tests.append({
                "name": "project_phase_1",
                "score": 0.0,
                "max_score": TOTAL_POINTS,
                "output": "Hash mismatch detected.",
            })
            return 0.0, 0.0, 0.0, notes, tests
        hash_status = "REPORT_MISMATCH" if report_mismatch else "OK"
        if report_mismatch:
            notes.append("submission_report.log hash mismatch detected (non-fatal).")

    summary_path = submission_root / "project_phase_1_grade_summary.json"
    if not summary_path.exists():
        notes.append("project_phase_1_grade_summary.json not found.")
        notes.insert(0, f"Hash status: {hash_status}")
        tests.append({
            "name": "project_phase_1",
            "score": 0.0,
            "max_score": TOTAL_POINTS,
            "output": "Missing project summary JSON.",
        })
        return 0.0, 0.0, 0.0, notes, tests

    try:
        summary = json.loads(summary_path.read_text(errors="ignore"))
    except json.JSONDecodeError:
        notes.append("project_phase_1_grade_summary.json is invalid JSON.")
        notes.insert(0, f"Hash status: {hash_status}")
        tests.append({
            "name": "project_phase_1",
            "score": 0.0,
            "max_score": TOTAL_POINTS,
            "output": "Invalid project summary JSON.",
        })
        return 0.0, 0.0, 0.0, notes, tests

    supplied = summary.get("supplied", {})
    student = summary.get("student_custom", {})
    tests_data = summary.get("tests", [])

    supplied_total = 0
    supplied_pass = 0
    extra_total = 0
    extra_pass = 0
    student_total = int(student.get("tests", 0))
    student_pass = int(student.get("passed", 0))
    student_fail = int(student.get("failed", max(0, student_total - student_pass)))

    group_totals: Dict[str, int] = {}
    group_passes: Dict[str, int] = {}
    for t in tests_data:
        name = str(t.get("test", "")).strip()
        category = str(t.get("category", ""))
        status = str(t.get("status", "")).upper()

        if category == "student_custom":
            continue
        if is_phase_1_extra_credit_test(name):
            extra_total += 1
            if status == "PASS":
                extra_pass += 1
            continue
        if category != "supplied":
            continue

        supplied_total += 1
        if status == "PASS":
            supplied_pass += 1

        group = normalize_group(str(t.get("group", "unknown")))
        group_totals[group] = group_totals.get(group, 0) + 1
        if status == "PASS":
            group_passes[group] = group_passes.get(group, 0) + 1

    if supplied_total == 0 and extra_total == 0 and not tests_data:
        supplied_total = int(supplied.get("tests", 0))
        supplied_pass = int(supplied.get("passed", 0))

    supplied_fail = max(0, supplied_total - supplied_pass)
    extra_fail = max(0, extra_total - extra_pass)

    base_points = float(supplied_pass)
    offset_points = PHASE_1_OFFSET_POINTS
    extra_credit_points = float(extra_pass)
    bonus_points = 0.0
    perfect_groups: List[str] = []
    for group, total in sorted(group_totals.items()):
        passed = group_passes.get(group, 0)
        if total > 0 and passed == total:
            perfect_groups.append(group)
            bonus_points += 0.10 * float(total)

    capped_points_before_extra = min(TOTAL_POINTS, base_points + offset_points + bonus_points)
    uncapped_points = capped_points_before_extra + extra_credit_points
    final_points = min(TOTAL_POINTS + extra_credit_points, uncapped_points)
    raw_percent = 0.0 if TOTAL_POINTS <= 0 else (final_points / TOTAL_POINTS) * 100.0

    notes.insert(0, f"Hash status: {hash_status}")
    notes.append("Scoring policy: supplied tests + Phase 1 offset + Phase 1 extra credit")
    notes.append(f"Supplied tests: {supplied_total} total, {supplied_pass} passed, {supplied_fail} failed")
    notes.append(f"Phase 1 extra-credit tests: {extra_total} total, {extra_pass} passed, {extra_fail} failed")
    notes.append(f"Student tests: {student_total} total, {student_pass} passed, {student_fail} failed (not scored)")
    notes.append(f"Base points (1 per supplied pass): {base_points:.2f}")
    notes.append(f"Phase 1 offset points: {offset_points:.2f}")
    notes.append(f"Extra-credit points (1 per extra-credit pass): {extra_credit_points:.2f}")
    notes.append(f"Bonus points (+10% per perfect supplied group): {bonus_points:.2f}")
    notes.append(f"Perfect supplied groups: {', '.join(perfect_groups) if perfect_groups else '(none)'}")
    notes.append(f"Points before extra credit cap: {capped_points_before_extra:.2f}")
    notes.append(f"Final points after extra credit: {final_points:.2f}")
    if base_points + offset_points + bonus_points > TOTAL_POINTS:
        notes.append(f"Hard cap applied: {TOTAL_POINTS:.2f}")

    tests.append({
        "name": "project_phase_1_supplied",
        "score": round(final_points, 2),
        "max_score": TOTAL_POINTS,
        "output": (
            f"Passes: {supplied_pass}/{supplied_total} supplied tests; "
            f"offset={offset_points:.2f}; extra={extra_credit_points:.2f}; "
            f"bonus={bonus_points:.2f}; capped_before_extra={capped_points_before_extra:.2f}; "
            f"final={final_points:.2f}; base_cap={TOTAL_POINTS:.2f}"
        ),
    })

    return raw_percent, final_points, bonus_points + extra_credit_points, notes, tests


def main() -> int:
    sub_root = Path.cwd()

    raw_percent, final_points, bonus_points, notes, tests = run_assignment_tests(sub_root)
    raw_percent = clamp(raw_percent)
    curved_percent = raw_percent
    final_score = final_points

    print("=== Grading Summary ===")
    print(f"Total points: {TOTAL_POINTS:.2f}")
    print(f"Raw percent : {raw_percent:.2f}%")
    print(f"Curved pct  : {curved_percent:.2f}%")
    print(f"Final score : {final_score:.2f} / {TOTAL_POINTS:.2f}")
    print(f"Bonus points: {bonus_points:.2f}")
    print("autograder_messages=[]")
    print("-----------------------")
    for note in notes:
        print(note)

    print(f"raw_score= {raw_percent:.2f}")
    print(f"curved_percent= {curved_percent:.2f}")
    print(f"final_score= {final_score:.2f}")
    print("timing_flag=no_curve")

    for t in tests:
        print(f"[TEST] {t['name']} {t['score']}/{t['max_score']} {t.get('output','')}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
