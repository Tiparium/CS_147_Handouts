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

  local rc=0
  set +e
  wait "$pid" 2>/dev/null
  rc=$?
  set -e
  if [ "$rc" -gt 128 ]; then
    # When spinner_wait runs in a helper/background shell, the tracked pid is
    # often not a direct child of that shell. In that case `wait` reports an
    # error; the caller is responsible for collecting the real command status.
    rc=0
  fi
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

# Start/stop helpers for manual spinner control (e.g., long loops).
spinner_start() {
  local label="${1:-Working}"
  local start_ts="${2:-$(date +%s)}"
  local chars='|/-\\'
  local i=0

  if [ -t 1 ]; then
    (
      while true; do
        local current_label="$label"
        if [ -n "${SPINNER_LABEL_FILE:-}" ] && [ -f "$SPINNER_LABEL_FILE" ]; then
          current_label="$(cat "$SPINNER_LABEL_FILE" 2>/dev/null || echo "$label")"
        fi
        local elapsed=$(( $(date +%s) - start_ts ))
        local mins=$((elapsed / 60))
        local secs=$((elapsed % 60))
        printf "\r  [INFO] %s: %s %02d:%02d" "$current_label" "${chars:i:1}" "$mins" "$secs" >&2
        if command -v tput >/dev/null 2>&1; then
          tput el >&2
        else
          printf "   " >&2
        fi
        i=$(( (i + 1) % ${#chars} ))
        sleep 0.2
      done
    ) &
    SPINNER_PID=$!
    SPINNER_START_TS="$start_ts"
    SPINNER_LABEL="$label"
  fi
}

spinner_stop() {
  if [ -n "${SPINNER_PID:-}" ]; then
    kill "$SPINNER_PID" >/dev/null 2>&1 || true
    wait "$SPINNER_PID" 2>/dev/null || true
    local elapsed=$(( $(date +%s) - ${SPINNER_START_TS:-$(date +%s)} ))
    local mins=$((elapsed / 60))
    local secs=$((elapsed % 60))
    if [ -t 1 ]; then
      printf "\r  [INFO] %s completed in %02d:%02d" "${SPINNER_LABEL:-Working}" "$mins" "$secs" >&2
      if command -v tput >/dev/null 2>&1; then
        tput el >&2
      else
        printf "   " >&2
      fi
      printf "\n" >&2
    else
      printf "  [INFO] %s completed in %02d:%02d\n" "${SPINNER_LABEL:-Working}" "$mins" "$secs" >&2
    fi
    unset SPINNER_PID SPINNER_START_TS SPINNER_LABEL
  fi
}

spinner_stop_quiet() {
  if [ -n "${SPINNER_PID:-}" ]; then
    kill "$SPINNER_PID" >/dev/null 2>&1 || true
    wait "$SPINNER_PID" 2>/dev/null || true
    if [ -t 1 ]; then
      printf "\r" >&2
      if command -v tput >/dev/null 2>&1; then
        tput el >&2
      else
        printf "   " >&2
      fi
    fi
    unset SPINNER_PID SPINNER_START_TS SPINNER_LABEL
  fi
}

spinner_abort() {
  if [ -n "${SPINNER_PID:-}" ]; then
    kill "$SPINNER_PID" >/dev/null 2>&1 || true
    wait "$SPINNER_PID" 2>/dev/null || true
    if [ -t 1 ]; then
      printf "\r  [INFO] %s aborted" "${SPINNER_LABEL:-Working}" >&2
      if command -v tput >/dev/null 2>&1; then
        tput el >&2
      else
        printf "   " >&2
      fi
      printf "\n" >&2
    else
      printf "  [INFO] %s aborted\n" "${SPINNER_LABEL:-Working}" >&2
    fi
    unset SPINNER_PID SPINNER_START_TS SPINNER_LABEL
  fi
}

spinner_pause() {
  if [ -n "${SPINNER_PID:-}" ]; then
    kill "$SPINNER_PID" >/dev/null 2>&1 || true
    wait "$SPINNER_PID" 2>/dev/null || true
    if [ -t 1 ]; then
      printf "\r" >&2
      if command -v tput >/dev/null 2>&1; then
        tput el >&2
      else
        printf "   " >&2
      fi
    fi
    unset SPINNER_PID
  fi
}

spinner_resume() {
  if [ -n "${SPINNER_START_TS:-}" ] && [ -n "${SPINNER_LABEL:-}" ]; then
    spinner_start "$SPINNER_LABEL" "$SPINNER_START_TS"
  fi
}
