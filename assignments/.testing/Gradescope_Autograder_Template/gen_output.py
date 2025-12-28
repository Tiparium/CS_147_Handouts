#!/usr/bin/env python3
import argparse
import json
import re
from pathlib import Path
from typing import Optional, Tuple

# Per-assignment defaults (CLI flags override these).
CONFIG = {
    "assignment_name": "Programming Assignment",
    "total_points": 100.0,
}


def parse_scores(text: str) -> Tuple[Optional[float], Optional[float], Optional[float]]:
    raw = curved = final = None

    m_raw = re.search(r"raw_score\s*=\s*\[?\s*([0-9]+(?:\.[0-9]+)?)", text)
    if m_raw:
        raw = float(m_raw.group(1))

    m_curved = re.search(r"curved_percent\s*=\s*\[?\s*([0-9]+(?:\.[0-9]+)?)", text)
    if m_curved:
        curved = float(m_curved.group(1))

    m_final = re.search(r"final_score\s*=\s*\[?\s*([0-9]+(?:\.[0-9]+)?)", text)
    if m_final:
        final = float(m_final.group(1))

    return raw, curved, final


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--in", dest="in_path", required=True)
    ap.add_argument("--out", dest="out_path", required=True)
    ap.add_argument("--assignment-name", default=CONFIG.get("assignment_name", "Programming Assignment"))
    ap.add_argument("--total-points", type=float, default=CONFIG.get("total_points", 100.0))
    args = ap.parse_args()

    in_path = Path(args.in_path)
    out_path = Path(args.out_path)

    text = in_path.read_text(errors="ignore") if in_path.is_file() else ""
    raw, curved, final = parse_scores(text)

    total_points = float(args.total_points)

    raw = raw if raw is not None else 0.0
    curved = curved if curved is not None else raw
    final_points = final if final is not None else (curved * total_points / 100.0)

    # round finals for stable reporting
    final_points = round(final_points, 2)
    curved = round(curved, 2)

    result = {
        "score": float(final_points),
        "visibility": "visible",
        "stdout_visibility": "visible",
        "tests": [
            {
                "name": args.assignment_name,
                "score": float(final_points),
                "max_score": total_points,
                "output": (
                    f"Raw percent: {raw}\n"
                    f"Adjusted percent: {curved}/100\n"
                    f"Final score: {final_points}/{total_points}"
                ),
                "visibility": "visible",
            }
        ],
    }

    out_path.write_text(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
