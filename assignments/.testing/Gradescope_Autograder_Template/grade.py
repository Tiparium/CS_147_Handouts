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

import os
import subprocess
from pathlib import Path
from typing import List, Tuple

# Per-assignment defaults (override via env: TOTAL_POINTS)
CONFIG = {
    "total_points": 100.0,
    "clamp_low": 0.0,
    "clamp_high": 100.0,
}

# Adjust this or set TOTAL_POINTS in the environment to change the final scale.
TOTAL_POINTS = float(os.environ.get("TOTAL_POINTS", CONFIG.get("total_points", 100)))
C_L = float(CONFIG.get("clamp_low", 0.0))
C_H = float(CONFIG.get("clamp_high", 100.0))


def run_assignment_tests(submission_root: Path) -> Tuple[float, List[str]]:
    """
    Run mux smoke tests via run_mux_tests.py.

    Return:
      raw_percent (float): percentage out of 100 before any curve/penalty.
      notes (List[str]): lines to include in grader_output.txt for visibility.
    """
    script = submission_root / "run_mux_tests.py"
    notes: List[str] = []

    if not script.exists():
        notes.append("run_mux_tests.py not found in submission.")
        return 0.0, notes

    proc = subprocess.run(
        ["python3", "-u", str(script)],
        cwd=submission_root,
        capture_output=True,
        text=True,
    )
    notes.append("[run_mux_tests.py stdout]")
    notes.extend(proc.stdout.strip().splitlines() if proc.stdout else ["(no stdout)"])
    if proc.stderr:
        notes.append("[run_mux_tests.py stderr]")
        notes.extend(proc.stderr.strip().splitlines())

    raw_percent = 100.0 if proc.returncode == 0 else 0.0
    return raw_percent, notes


def apply_curve(raw_percent: float) -> Tuple[float, str]:
    """
    Adjust the raw percentage if needed (late penalties, bonuses, etc.).
    Return (curved_percent, timing_flag).
    """
    return raw_percent, "no_curve"


def remap_score(curved_percent: float) -> float:
    """
    Convert the curved percentage into points using TOTAL_POINTS.
    """
    return (curved_percent * TOTAL_POINTS) / 100.0


def clamp(value: float, low: float = C_L, high: float = C_H) -> float:
    return max(low, min(high, value))


def main() -> int:
    sub_root = Path.cwd()

    raw_percent, notes = run_assignment_tests(sub_root)
    raw_percent = clamp(raw_percent)

    curved_percent, timing_flag = apply_curve(raw_percent)
    curved_percent = clamp(curved_percent)

    final_score = remap_score(curved_percent)

    print("[grading summary]")
    for note in notes:
        print(note)
    print(f"raw_score= {raw_percent:.2f}")
    print(f"curved_percent= {curved_percent:.2f}")
    print(f"final_score= {final_score:.2f}")
    print(f"timing_flag={timing_flag}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
