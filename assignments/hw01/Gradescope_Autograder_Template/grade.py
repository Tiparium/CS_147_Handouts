#!/usr/bin/env python3
"""
Template grader.

Replace `run_assignment_tests` and (optionally) `apply_curve` with assignment-
specific logic. The grader should print three key lines that gen_output.py will
parse:

  raw_score= <percent out of 100>
  curved_percent= <percent out of 100 after adjustments>
  final_score= <points after remapping to the assignment's total>
"""

from __future__ import annotations

import hashlib
import os
from pathlib import Path
from typing import Dict, List, Tuple

CONFIG = {
    "clamp_low": 0.0,
    "clamp_high": 100.0,
    # Per-subproblem points; add/remove entries per assignment.
    "sub_points": {
        "hw1_1": 10.0,
        "hw1_2": 10.0,
        "hw1_3": 10.0,
    },
}

# Build subproblem -> points mapping directly from config
SUB_POINTS: Dict[str, float] = {k: float(v) for k, v in CONFIG.get("sub_points", {}).items()}
# Total points = sum of subproblem points
TOTAL_POINTS = sum(SUB_POINTS.values()) if SUB_POINTS else 100.0
C_L = float(CONFIG.get("clamp_low", 0.0))
C_H = float(CONFIG.get("clamp_high", 100.0))


def clamp(value: float, low: float = C_L, high: float = C_H) -> float:
    return max(low, min(high, value))


def parse_hash_block(report_path: Path) -> Tuple[Dict[str, str], List[str]]:
    """Parse leading hash lines (sha256sum format) from the report."""
    hashes: Dict[str, str] = {}
    lines: List[str] = []
    if not report_path.exists():
        return hashes, lines
    with report_path.open() as f:
        for line in f:
            stripped = line.strip()
            if not stripped:
                continue
            parts = stripped.split(None, 1)
            if len(parts) == 2 and all(c in "0123456789abcdef" for c in parts[0].lower()):
                digest, path = parts
                norm_path = path.strip().lstrip("./")
                hashes[norm_path] = digest
            else:
                # Reached non-hash lines; stop here
                lines.append(stripped)
                break
        # include remaining lines (already read one)
        for line in f:
            lines.append(line.rstrip("\n"))
    return hashes, lines


def recompute_hashes(submission_root: Path) -> Dict[str, str]:
    out: Dict[str, str] = {}
    files = sorted(submission_root.rglob("*.v")) + sorted(submission_root.rglob("*.sv"))
    for path in files:
        rel = str(path.relative_to(submission_root)).lstrip("./")
        with path.open("rb") as f:
            digest = hashlib.sha256(f.read()).hexdigest()
        out[rel] = digest
    return out


def parse_test_summary(lines: List[str]) -> Tuple[List[Dict], List[str]]:
    """Parse test_runner quiet summary lines into test entries."""
    tests = []
    notes: List[str] = []
    for line in lines:
        if line.startswith("[PASS]") or line.startswith("[FAIL]"):
            status, rest = line.split("]", 1)
            status = status.strip("[]")
            name_part, _, detail = rest.strip().partition(" ")
            sub_name = name_part
            max_score = SUB_POINTS.get(sub_name, 0.0)
            score = max_score if status == "PASS" else 0.0
            tests.append(
                {
                    "name": sub_name,
                    "score": score,
                    "max_score": max_score,
                    "output": detail.strip(),
                }
            )
    if not tests:
        notes.append("No test summary entries parsed.")
    return tests, notes


def run_assignment_tests(submission_root: Path) -> Tuple[float, float, List[str], List[Dict]]:
    """Grade based on submission_report.txt (quiet) and hashes.

    Returns:
      earned_points, total_points, notes, tests
    """
    notes: List[str] = []
    report_path = submission_root / "submission_report.log"
    verbose_path = submission_root / "submission_report_verbose.log"

    expected_hashes, lines = parse_hash_block(report_path)
    actual_hashes = recompute_hashes(submission_root)

    # Hash check
    if expected_hashes:
        if expected_hashes != actual_hashes:
            notes.append("Hash mismatch between report and submission files.")
            return 0.0, sum(SUB_POINTS.values()), notes, []
    else:
        notes.append("No hash block found in submission_report.log.")

    tests, test_notes = parse_test_summary(lines)
    notes.extend(test_notes)

    if verbose_path.exists():
        notes.append("[verbose test log]")
        notes.extend(verbose_path.read_text().splitlines())

    total_points = sum(t.get("max_score", 0.0) for t in tests)
    earned = sum(t.get("score", 0.0) for t in tests)
    return earned, total_points, notes, tests


def apply_curve(raw_percent: float) -> Tuple[float, str]:
    return raw_percent, "no_curve"


def remap_score(curved_percent: float) -> float:
    return (curved_percent * TOTAL_POINTS) / 100.0


def main() -> int:
    sub_root = Path.cwd()

    earned_points, total_points_calc, notes, tests = run_assignment_tests(sub_root)
    if not total_points_calc:
        total_points_calc = TOTAL_POINTS
    total_pts = total_points_calc or 1.0  # avoid division by zero

    raw_percent = (earned_points / total_pts) * 100.0
    raw_percent = clamp(raw_percent)

    curved_percent, timing_flag = apply_curve(raw_percent)
    curved_percent = clamp(curved_percent)

    final_score = (curved_percent / 100.0) * total_pts

    print("=== Grading Summary ===")
    print(f"Total points: {total_pts:.2f}")
    print(f"Raw percent : {raw_percent:.2f}%")
    print(f"Curve note  : {timing_flag}")
    print(f"Curved pct  : {curved_percent:.2f}%")
    print(f"Final score : {final_score:.2f} / {total_pts:.2f}")
    print("-----------------------")
    for note in notes:
        print(note)
    print(f"raw_score= {raw_percent:.2f}")
    print(f"curved_percent= {curved_percent:.2f}")
    print(f"final_score= {final_score:.2f}")
    print(f"timing_flag={timing_flag}")
    # Emit tests for Gradescope parser
    if tests:
        for t in tests:
            name = t.get("name")
            sc = t.get("score")
            ms = t.get("max_score")
            out = t.get("output") or ""
            print(f"[TEST] {name} {sc}/{ms} {out}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
