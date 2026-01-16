#!/usr/bin/env bash

set -euo pipefail

spinner_wait() {
  local pid="$1"
  local label="${2:-Working}"
  local start_ts="${3:-$(date +%s)}"
  local chars='|/-\\'
  local i=0

  if [ -t 1 ]; then
    while kill -0 "$pid" 2>/dev/null; do
      local elapsed=$(( $(date +%s) - start_ts ))
      local mins=$((elapsed / 60))
      local secs=$((elapsed % 60))
      printf "\r  [INFO] %s: %s %02d:%02d" "$label" "${chars:i:1}" "$mins" "$secs" >&2
      if command -v tput >/dev/null 2>&1; then
        tput el >&2
      else
        printf "   " >&2
      fi
      i=$(( (i + 1) % ${#chars} ))
      sleep 0.2
    done
  fi

  wait "$pid"; local rc=$?
  local elapsed=$(( $(date +%s) - start_ts ))
  local mins=$((elapsed / 60))
  local secs=$((elapsed % 60))
  SPINNER_ELAPSED_SECONDS="$elapsed"
  SPINNER_ELAPSED="$(printf "%02d:%02d" "$mins" "$secs")"
  if [ -t 1 ]; then
    printf "\r  [INFO] %s completed in %02d:%02d" "$label" "$mins" "$secs" >&2
    if command -v tput >/dev/null 2>&1; then
      tput el >&2
    else
      printf "   " >&2
    fi
    printf "\n" >&2
  else
    printf "  [INFO] %s completed in %02d:%02d\n" "$label" "$mins" "$secs" >&2
  fi
  return $rc
}

run_with_spinner() {
  local label="$1"; shift
  "$@" &
  local pid=$!
  spinner_wait "$pid" "$label"
}
