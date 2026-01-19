#!/usr/bin/env bash

set -euo pipefail

ASM="/repo/assignments/tools/assembler/assemble.sh"
SIM="/repo/assignments/tools/simulator/wiscalculator"

if [ ! -x "$ASM" ]; then
  echo "Assembler not executable: $ASM" >&2
  exit 1
fi
if [ ! -x "$SIM" ]; then
  echo "Simulator not executable: $SIM" >&2
  exit 1
fi

tmpdir="$(mktemp -d)"
asm_src="$tmpdir/smoke.asm"
out_prefix="$tmpdir/loadfile"

printf "halt\n" >"$asm_src"
echo "[probe] assembling $asm_src -> $out_prefix"
"$ASM" "$asm_src" "$out_prefix"

echo "[probe] outputs:"
ls -1 "$tmpdir"

if [ -f "${out_prefix}_all.img" ]; then
  img="${out_prefix}_all.img"
elif [ -f "${out_prefix}_0.img" ]; then
  img="${out_prefix}_0.img"
else
  echo "[probe] no .img outputs found to simulate."
  exit 0
fi

if command -v timeout >/dev/null 2>&1; then
  echo "[probe] simulating $img (timeout 3s)"
  timeout 3s "$SIM" "$img" || true
else
  echo "[probe] timeout not available; run manually:"
  echo "  $SIM $img"
fi
