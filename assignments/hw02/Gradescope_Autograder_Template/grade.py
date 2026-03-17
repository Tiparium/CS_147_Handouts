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
import json
import os
from pathlib import Path
from typing import Dict, List, Tuple, Optional

VERBOSE = os.environ.get("AG_VERBOSE", os.environ.get("VERBOSE", "0")) not in ("0", "", "false", "False", None)
HASH_VERBOSE = os.environ.get("AG_HASH_VERBOSE", "0") not in ("0", "", "false", "False", None)

CONFIG = {
    "clamp_low": 0.0,
    "clamp_high": 100.0,
    # Per-subproblem points; add/remove entries per assignment.
    "sub_points": {
        "hw2_1": 20.0,
        "hw2_2": 30.0,
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
    files = sorted(submission_root.rglob("*.v")) + sorted(submission_root.rglob("*.sv"))
    for path in files:
        rel = str(path.relative_to(submission_root)).lstrip("./")
        with path.open("rb") as f:
            digest = hashlib.sha256(f.read()).hexdigest()
        out[rel] = digest
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
    hash_status = "UNKNOWN"
    report_path = submission_root / "submission_report.log"
    verbose_path = submission_root / "submission_report_verbose.log"

    expected_hashes, lines = parse_hash_block(report_path)
    actual_hashes = recompute_hashes(submission_root)

    def hash_report(title: str, mapping: Dict[str, str]) -> List[str]:
        rep: List[str] = []
        rep.append(f"================ {title} ================")
        if not mapping:
            rep.append("(no entries)")
        else:
            for path in sorted(mapping.keys()):
                rep.append(f"{path}: {mapping[path]}")
            joined = "\n".join(f"{k}:{mapping[k]}" for k in sorted(mapping.keys()))
            summary = hashlib.sha256(joined.encode("utf-8")).hexdigest() if joined else "n/a"
            rep.append(f"Summary hash: {summary}")
        rep.append("=" * len(rep[0]))
        return rep

    # Hash check policy:
    # - Source/file hash mismatches are fatal (0 points).
    # - submission_report.log hash mismatch is warning-only.
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
            notes.append("Hash mismatch between expected and actual submission files.")
            notes.insert(0, f"Hash status: {hash_status}")
            if VERBOSE or HASH_VERBOSE:
                notes.extend(hash_report("HASH REPORT (expected source)", expected_files))
                notes.extend(hash_report("HASH REPORT (actual source)", actual_files))
            return 0.0, sum(SUB_POINTS.values()), notes, []

        if report_mismatch:
            hash_status = "REPORT_MISMATCH"
            notes.append("submission_report.log hash mismatch detected (non-fatal).")
        else:
            hash_status = "OK"
    else:
        hash_status = "MISSING"
        notes.append("No hash block found in submission_report.log.")

    tests, test_notes = parse_test_summary(lines)
    notes.extend(test_notes)

    if verbose_path.exists():
        notes.append("[verbose test log]")
        notes.extend(verbose_path.read_text().splitlines())

    # Surface hash status prominently
    notes.insert(0, f"Hash status: {hash_status}")
    if VERBOSE or HASH_VERBOSE:
        notes.extend(hash_report("HASH REPORT (expected)", expected_hashes))
        notes.extend(hash_report("HASH REPORT (actual)", actual_hashes))

    total_points = sum(t.get("max_score", 0.0) for t in tests)
    earned = sum(t.get("score", 0.0) for t in tests)
    return earned, total_points, notes, tests


def apply_curve(raw_percent: float) -> float:
    return raw_percent


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

    curved_percent = apply_curve(raw_percent)
    curved_percent = clamp(curved_percent)

    final_score = (curved_percent / 100.0) * total_pts

    print("=== Grading Summary ===")
    print(f"Total points: {total_pts:.2f}")
    print(f"Raw percent : {raw_percent:.2f}%")
    print(f"Curved pct  : {curved_percent:.2f}%")
    print(f"Final score : {final_score:.2f} / {total_pts:.2f}")
    messages = []
    print(f"autograder_messages={json.dumps(messages)}")
    print("-----------------------")
    for note in notes:
        print(note)
    print(f"raw_score= {raw_percent:.2f}")
    print(f"curved_percent= {curved_percent:.2f}")
    print(f"final_score= {final_score:.2f}")
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
