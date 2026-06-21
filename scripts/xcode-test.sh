#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA="$(mktemp -d "${TMPDIR:-/tmp}/RecipeSwipe-DerivedData.XXXXXX")"
RESULT_DIRECTORY="$(mktemp -d "${TMPDIR:-/tmp}/RecipeSwipe-TestResults.XXXXXX")"
RESULT_BUNDLE="$RESULT_DIRECTORY/RecipeSwipeTests.xcresult"
SIMCTL_OUTPUT="$(mktemp "${TMPDIR:-/tmp}/RecipeSwipe-Simctl.XXXXXX")"
SIMCTL_TIMEOUT="${RECIPESWIPE_SIMCTL_TIMEOUT:-60}"
XCODEBUILD_TIMEOUT="${RECIPESWIPE_XCODEBUILD_TIMEOUT:-600}"
XCRUN="${XCRUN:-xcrun}"
XCODEBUILD="${XCODEBUILD:-xcodebuild}"
WATCHDOG_PID=""

cleanup() {
  rm -rf "$DERIVED_DATA" "$RESULT_DIRECTORY" "$SIMCTL_OUTPUT"
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

run_with_timeout "$SIMCTL_TIMEOUT" "simctl list devices" "$XCRUN" simctl list devices available -j > "$SIMCTL_OUTPUT"
SIMCTL_JSON="$(<"$SIMCTL_OUTPUT")"
DEVICE_ID="$(printf '%s' "$SIMCTL_JSON" | ruby -rjson -e '
  devices = JSON.parse(STDIN.read).fetch("devices").values.flatten
  phone = devices.find { |device| device["isAvailable"] && device["name"].start_with?("iPhone") }
  abort "no available iPhone simulator" unless phone
  puts phone.fetch("udid")
')"

run_with_timeout "$XCODEBUILD_TIMEOUT" "xcodebuild test" "$XCODEBUILD" test \
  -workspace "$ROOT/RecipeSwipe.xcworkspace" \
  -scheme RecipeSwipe \
  -destination "platform=iOS Simulator,id=$DEVICE_ID" \
  -derivedDataPath "$DERIVED_DATA" \
  -resultBundlePath "$RESULT_BUNDLE" \
  CODE_SIGNING_ALLOWED=NO \
  IPHONEOS_DEPLOYMENT_TARGET=12.0
