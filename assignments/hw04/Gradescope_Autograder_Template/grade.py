#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import os
import re
from pathlib import Path
from typing import Dict, List, Optional, Tuple

VERBOSE = os.environ.get("AG_VERBOSE", os.environ.get("VERBOSE", "0")) not in ("0", "", "false", "False", None)
HASH_VERBOSE = os.environ.get("AG_HASH_VERBOSE", "0") not in ("0", "", "false", "False", None)
EXPECTED_SUBPROBLEMS = ("hw4_1", "hw4_2")


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
                norm_path = path.strip().lstrip("./")
                hashes[norm_path] = digest
            else:
                lines.append(stripped)
                break
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
    files = (
        sorted(submission_root.rglob("*.v"))
        + sorted(submission_root.rglob("*.sv"))
        + sorted(submission_root.rglob("*.asm"))
        + sorted(submission_root.rglob("*.txt"))
    )
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
    tests: List[Dict] = []
    notes: List[str] = []
    seen: set[str] = set()
    for line in lines:
        if line.startswith("[PASS]") or line.startswith("[FAIL]"):
            status = "PASS" if line.startswith("[PASS]") else "FAIL"
            payload = line.split("]", 1)[1].strip()
            sub_name = payload.split(" ", 1)[0].strip()
            detail = payload[len(sub_name):].strip()
            if sub_name in EXPECTED_SUBPROBLEMS:
                seen.add(sub_name)
            tests.append(
                {
                    "name": sub_name,
                    "status": status,
                    "output": detail,
                }
            )
    for expected in EXPECTED_SUBPROBLEMS:
        if expected not in seen:
            notes.append(f"Missing summary line for {expected}.")
            tests.append({"name": expected, "status": "FAIL", "output": "Missing summary line."})
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
        joined = "\n".join(f"{k}:{mapping[k]}" for k in sorted(mapping.keys()))
        summary = hashlib.sha256(joined.encode("utf-8")).hexdigest() if joined else "n/a"
        rep.append(f"Summary hash: {summary}")
    rep.append("=" * len(rep[0]))
    return rep


def main() -> int:
    sub_root = Path.cwd()
    notes: List[str] = []

    report_path = sub_root / "submission_report.log"
    verbose_path = sub_root / "submission_report_verbose.log"

    expected_hashes, lines = parse_hash_block(report_path)
    actual_hashes = recompute_hashes(sub_root)

    hash_ok = True
    hash_status = "UNKNOWN"
    if expected_hashes:
        expected_files = {k: v for k, v in expected_hashes.items() if k != "submission_report.log"}
        expected_report = expected_hashes.get("submission_report.log")
        actual_files = recompute_expected_hashes(sub_root, list(expected_files.keys()))

        source_mismatch = expected_files != actual_files
        report_mismatch = False
        if expected_report is not None:
            actual_report = _hash_report_body(sub_root / "submission_report.log")
            report_mismatch = (actual_report != expected_report)

        if source_mismatch:
            hash_status = "MISMATCH"
            hash_ok = False
            notes.append("Hash mismatch between expected and actual submission files.")
        elif report_mismatch:
            hash_status = "REPORT_MISMATCH"
            notes.append("submission_report.log hash mismatch detected (non-fatal).")
        else:
            hash_status = "OK"
    else:
        hash_status = "MISSING"
        notes.append("No hash block found in submission_report.log.")

    tests, test_notes = parse_test_summary(lines)
    notes.extend(test_notes)

    tests_ok = all(t.get("status") == "PASS" for t in tests if t.get("name") in EXPECTED_SUBPROBLEMS)
    final_status = "PASS" if (hash_ok and tests_ok) else "FAIL"

    notes.insert(0, f"Hash status: {hash_status}")
    if VERBOSE or HASH_VERBOSE:
        notes.extend(hash_report("HASH REPORT (expected)", expected_hashes))
        notes.extend(hash_report("HASH REPORT (actual)", actual_hashes))
    if verbose_path.exists() and VERBOSE:
        notes.append("[verbose test log]")
        notes.extend(verbose_path.read_text().splitlines())

    print("=== Grading Summary ===")
    print("Assignment mode: pass/fail only (hand graded).")
    print(f"Final status : {final_status}")
    print(f"final_status= {final_status}")
    print("-----------------------")
    for note in notes:
        print(note)
    for t in tests:
        print(f"[TEST] {t['name']} {t['status']} {t.get('output','')}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
