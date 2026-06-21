#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRATCH="$(mktemp -d "${TMPDIR:-/tmp}/RecipeSwipe-SPM.XXXXXX")"

cleanup() {
  rm -rf "$SCRATCH"
}

handle_signal() {
  local signal="$1"
  cleanup
  trap - "$signal"
  kill "-$signal" "$$"
}

trap cleanup EXIT
trap 'handle_signal HUP' HUP
trap 'handle_signal INT' INT
trap 'handle_signal TERM' TERM

swift test --package-path "$ROOT" --scratch-path "$SCRATCH"
