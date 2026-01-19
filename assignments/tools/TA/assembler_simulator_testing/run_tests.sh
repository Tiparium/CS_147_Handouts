#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASM="/repo/assignments/tools/assembler/assemble.sh"
SIM="/repo/assignments/tools/simulator/wiscalculator"
OUT_FILE="$SCRIPT_DIR/probe_outputs.out"

cases=(
  good_halt.asm
  good_basic.asm
  bad_opcode.asm
  bad_reg.asm
  bad_syntax.asm
  empty.asm
)

rm -f "$OUT_FILE"

log_line() {
  printf "%s\n" "$1" >>"$OUT_FILE"
}

for case_file in "${cases[@]}"; do
  asm_path="$SCRIPT_DIR/$case_file"
  tmpdir="$(mktemp -d)"
  out_prefix="$tmpdir/loadfile"
  log_line "==============================="
  log_line "[CASE] $case_file"
  log_line "[CMD ] $ASM $case_file $out_prefix"

  set +e
  "$ASM" "$asm_path" "$out_prefix" >>"$OUT_FILE" 2>&1
  asm_rc=$?
  set -e
  log_line "[RC  ] assembler=$asm_rc"

  if [ $asm_rc -ne 0 ]; then
    rm -rf "$tmpdir"
    log_line "[SKIP] simulator (assemble failed)"
    continue
  fi

  sim_img=""
  if [ -f "${out_prefix}_all.img" ]; then
    sim_img="${out_prefix}_all.img"
  elif [ -f "${out_prefix}_0.img" ]; then
    sim_img="${out_prefix}_0.img"
  fi

  if [ -z "$sim_img" ]; then
    log_line "[SKIP] simulator (no .img output)"
    rm -rf "$tmpdir"
    continue
  fi

  log_line "[CMD ] $SIM $sim_img"
  set +e
  if command -v timeout >/dev/null 2>&1; then
    timeout 5s "$SIM" "$sim_img" >>"$OUT_FILE" 2>&1
    sim_rc=$?
  else
    "$SIM" "$sim_img" >>"$OUT_FILE" 2>&1
    sim_rc=$?
  fi
  set -e
  log_line "[RC  ] simulator=$sim_rc"

  rm -rf "$tmpdir"
  log_line ""
done

log_line "==============================="
log_line "[DONE] Outputs written to probe_outputs.out"
