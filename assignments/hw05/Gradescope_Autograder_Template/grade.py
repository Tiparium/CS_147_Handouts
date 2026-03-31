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
    "sub_points": {
        "hw5_1": 35.0,
        "hw5_2": 35.0,
    },
}

SUB_POINTS: Dict[str, float] = {k: float(v) for k, v in CONFIG["sub_points"].items()}
EXPECTED_SUBPROBLEMS = tuple(SUB_POINTS.keys())
TOTAL_POINTS = sum(SUB_POINTS.values())
DISPLAY_TOTAL_POINTS = 0.0


def parse_hash_block(report_path: Path) -> Tuple[Dict[str, str], List[str]]:
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
                hashes[path.strip().lstrip("./")] = digest
            else:
                lines.append(stripped)
                break
        for line in f:
            lines.append(line.rstrip("\n"))
    return hashes, lines


def hash_report_body(report_path: Path) -> Optional[str]:
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
    return hashlib.sha256("".join(body_lines).encode("utf-8")).hexdigest()


def parse_test_summary(lines: List[str]) -> Tuple[List[Dict], List[str]]:
    tests: List[Dict] = []
    notes: List[str] = []
    seen: set[str] = set()
    for line in lines:
        if line.startswith("[PASS]") or line.startswith("[FAIL]"):
            status = "PASS" if line.startswith("[PASS]") else "FAIL"
            payload = line.split("]", 1)[1].strip()
            sub_name = payload.split(" ", 1)[0].strip()
            detail = payload[len(sub_name):].strip()
            if sub_name not in SUB_POINTS:
                continue
            seen.add(sub_name)
            tests.append(
                {
                    "name": sub_name,
                    "status": status,
                    "score": 0.0,
                    "max_score": 0.0,
                    "output": detail,
                }
            )
    for expected in EXPECTED_SUBPROBLEMS:
        if expected not in seen:
            notes.append(f"Missing summary line for {expected}.")
            tests.append(
                {
                    "name": expected,
                    "status": "FAIL",
                    "score": 0.0,
                    "max_score": 0.0,
                    "output": "Missing summary line.",
                }
            )
    if not tests:
        notes.append("No test summary entries parsed.")
    return tests, notes


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


def main() -> int:
    sub_root = Path.cwd()
    notes: List[str] = []

    report_path = sub_root / "submission_report.log"
    verbose_path = sub_root / "submission_report_verbose.log"

    expected_hashes, lines = parse_hash_block(report_path)
    actual_report_hash = hash_report_body(report_path)
    expected_report_hash = expected_hashes.get("submission_report.log")

    actual_hashes: Dict[str, str] = {}
    if actual_report_hash is not None:
        actual_hashes["submission_report.log"] = actual_report_hash

    hash_ok = True
    hash_status = "UNKNOWN"
    if expected_report_hash:
        if actual_report_hash == expected_report_hash:
            hash_status = "OK"
        else:
            hash_status = "MISMATCH"
            hash_ok = False
            notes.append("submission_report.log hash mismatch detected.")
    else:
        hash_status = "MISSING"
        hash_ok = False
        notes.append("No report hash found in submission_report.log.")

    tests, test_notes = parse_test_summary(lines)
    notes.extend(test_notes)

    if not hash_ok:
        for test in tests:
            test["score"] = 0.0
            test["output"] = f"{test.get('output', '')} Hash mismatch detected.".strip()

    notes.insert(0, f"Hash status: {hash_status}")
    notes.append("Autograder mode: required-file reporting only.")
    notes.append("Manual grading will assign the actual HW5 points.")
    notes.append(f"Configured manual point split: hw5_1={SUB_POINTS['hw5_1']}, hw5_2={SUB_POINTS['hw5_2']}")
    notes.append(f"Displayed total points: {DISPLAY_TOTAL_POINTS}")
    if VERBOSE or HASH_VERBOSE:
        notes.extend(hash_report("HASH REPORT (expected)", {"submission_report.log": expected_report_hash} if expected_report_hash else {}))
        notes.extend(hash_report("HASH REPORT (actual)", actual_hashes))
    if verbose_path.exists() and VERBOSE:
        notes.append("[verbose test log]")
        notes.extend(verbose_path.read_text().splitlines())

    print("=== Grading Summary ===")
    print("Assignment mode: required-file reporting only (manual grading).")
    print(f"Total points: {DISPLAY_TOTAL_POINTS}")
    print("earned_points= 0.0")
    print(f"total_points= {DISPLAY_TOTAL_POINTS}")
    print("raw_score= 0.0")
    print("curved_percent= 0.0")
    print("final_score= 0.0")
    print("-----------------------")
    for note in notes:
        print(note)
    print(f"autograder_messages={json.dumps(notes)}")
    for test in tests:
        print(
            f"[TEST] {test['name']} {test['status']} "
            f"score={test['score']}/{test['max_score']} {test.get('output', '')}"
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
