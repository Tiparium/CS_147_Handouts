#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ASSIGNMENTS_ROOT="$REPO_ROOT/assignments"

usage() {
  echo "Usage: build_writeup.sh <hwXX> [hwYY ...]" >&2
  echo "       build_writeup.sh project <phase1|phase2|phase3>" >&2
  exit 1
}

if [ $# -lt 1 ]; then
  usage
fi

if ! command -v latexmk >/dev/null 2>&1; then
  echo "Error: latexmk not found. Install LaTeX locally before running writeup generation." >&2
  exit 1
fi

normalize_hw() {
  local name="$1"
  if [[ "$name" =~ ^hw([0-9]+)$ ]]; then
    printf "hw%02d\n" "${BASH_REMATCH[1]}"
  else
    printf "%s\n" "$name"
  fi
}

args=("$@")
i=0
while [ "$i" -lt "$#" ]; do
  raw_hw="${args[$i]}"
  if [ "$raw_hw" = "project" ]; then
    phase="${args[$((i + 1))]:-}"
    if [ -z "$phase" ]; then
      echo "[writeup] Missing project phase (phase1/phase2/phase3)." >&2
      exit 1
    fi
    case "$phase" in
      phase1|phase_1|1)
        writeup_dir="$ASSIGNMENTS_ROOT/project/demo1/writeup"
        label="project phase1"
        ;;
      phase2|phase_2|2)
        writeup_dir="$ASSIGNMENTS_ROOT/project/demo2/writeup"
        label="project phase2"
        ;;
      phase3|phase_3|3)
        writeup_dir="$ASSIGNMENTS_ROOT/project/demo3/writeup"
        label="project phase3"
        ;;
      *)
        echo "[writeup] Unknown project phase: $phase" >&2
        exit 1
        ;;
    esac
    i=$((i + 2))
  elif [ "$raw_hw" = "project_common" ]; then
    writeup_dir="$ASSIGNMENTS_ROOT/project/common/writeup"
    label="project common"
    i=$((i + 1))
  elif [ "$raw_hw" = "rules" ]; then
    writeup_dir="$ASSIGNMENTS_ROOT/tools/verilog_rules"
    label="rules"
    i=$((i + 1))
  else
    hw="$(normalize_hw "$raw_hw")"
    writeup_dir="$ASSIGNMENTS_ROOT/$hw/writeup"
    label="$hw"
    i=$((i + 1))
  fi
  if [ ! -d "$writeup_dir" ]; then
    echo "[writeup] Skipping $label (no writeup directory)."
    continue
  fi
  shopt -s nullglob
  tex_files=("$writeup_dir"/*.tex)
  shopt -u nullglob
  if [ "${#tex_files[@]}" -eq 0 ]; then
    echo "[writeup] Skipping $label (no .tex files)."
    continue
  fi
  for tex in "${tex_files[@]}"; do
    tex_base="$(basename "$tex")"
    tex_stem="${tex_base%.tex}"
    echo "[writeup] Building $label/$tex_base"
    # Clear stale latexmk state without touching the PDF.
    rm -f "$writeup_dir/$tex_stem.aux" "$writeup_dir/$tex_stem.fdb_latexmk" \
      "$writeup_dir/$tex_stem.fls" "$writeup_dir/$tex_stem.log" \
      "$writeup_dir/$tex_stem.out" "$writeup_dir/$tex_stem.toc"
    (cd "$writeup_dir" && latexmk -g -pdf -interaction=nonstopmode -halt-on-error "$tex_base")
    # Clean build artifacts while preserving the PDF and source.
    rm -f "$writeup_dir/$tex_stem.aux" "$writeup_dir/$tex_stem.fdb_latexmk" \
      "$writeup_dir/$tex_stem.fls" "$writeup_dir/$tex_stem.log" \
      "$writeup_dir/$tex_stem.out" "$writeup_dir/$tex_stem.toc"
  done
done
