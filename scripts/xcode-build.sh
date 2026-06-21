#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA="$(mktemp -d "${TMPDIR:-/tmp}/RecipeSwipe-Build.XXXXXX")"
XCODEBUILD_TIMEOUT="${RECIPESWIPE_XCODEBUILD_TIMEOUT:-600}"
XCODEBUILD="${XCODEBUILD:-xcodebuild}"
WATCHDOG_PID=""

cleanup() {
  rm -rf "$DERIVED_DATA"
}

handle_signal() {
  local signal="$1"
  if [[ -n "$WATCHDOG_PID" ]]; then
    kill "-$signal" "$WATCHDOG_PID" 2>/dev/null || true
    wait "$WATCHDOG_PID" 2>/dev/null || true
    WATCHDOG_PID=""
  fi
  cleanup
  trap - "$signal"
  kill "-$signal" "$$"
}

run_with_timeout() {
  ruby --disable-gems "$ROOT/scripts/run-with-timeout.rb" "$@" &
  WATCHDOG_PID=$!
  set +e
  wait "$WATCHDOG_PID"
  local exit_code=$?
  set -e
  WATCHDOG_PID=""
  return "$exit_code"
}

trap cleanup EXIT
trap 'handle_signal HUP' HUP
trap 'handle_signal INT' INT
trap 'handle_signal TERM' TERM

run_with_timeout "$XCODEBUILD_TIMEOUT" "xcodebuild build" "$XCODEBUILD" build \
  -workspace "$ROOT/RecipeSwipe.xcworkspace" \
  -scheme RecipeSwipe \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  IPHONEOS_DEPLOYMENT_TARGET=12.0
