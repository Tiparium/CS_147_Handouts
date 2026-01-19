#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JAVA_FILE="$SCRIPT_DIR/Assemble.java"
CLASS_FILE="$SCRIPT_DIR/Assemble.class"

if [ ! -f "$JAVA_FILE" ]; then
  echo "Assemble.java not found at $JAVA_FILE" >&2
  exit 1
fi

if [ ! -f "$CLASS_FILE" ]; then
  if ! command -v javac >/dev/null 2>&1; then
    echo "javac not found; cannot compile Assemble.java" >&2
    exit 1
  fi
  javac "$JAVA_FILE"
fi

if ! command -v java >/dev/null 2>&1; then
  echo "java not found; cannot run assembler" >&2
  exit 1
fi

exec java -cp "$SCRIPT_DIR" Assemble "$@"
