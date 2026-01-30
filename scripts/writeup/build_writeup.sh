#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ASSIGNMENTS_ROOT="$REPO_ROOT/assignments"

usage() {
  echo "Usage: build_writeup.sh <hwXX> [hwYY ...]" >&2
  exit 1
}

if [ $# -lt 1 ]; then
  usage
fi

if ! command -v latexmk >/dev/null 2>&1; then
  echo "Error: latexmk not found. Rebuild the Docker image after adding TeX packages." >&2
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

for raw_hw in "$@"; do
  if [ "$raw_hw" = "rules" ]; then
    writeup_dir="$ASSIGNMENTS_ROOT/tools/verilog_rules"
    label="rules"
  else
    hw="$(normalize_hw "$raw_hw")"
    writeup_dir="$ASSIGNMENTS_ROOT/$hw/writeup"
    label="$hw"
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
