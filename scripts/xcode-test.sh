#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA="$(mktemp -d "${TMPDIR:-/tmp}/RecipeSwipe-DerivedData.XXXXXX")"
SIMCTL_TIMEOUT="${RECIPESWIPE_SIMCTL_TIMEOUT:-15}"
XCRUN="${XCRUN:-xcrun}"

cleanup() {
  rm -rf "$DERIVED_DATA"
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

SIMCTL_JSON="$(ruby --disable-gems "$ROOT/scripts/run-with-timeout.rb" "$SIMCTL_TIMEOUT" "simctl list devices" "$XCRUN" simctl list devices available -j)"
DEVICE_ID="$(printf '%s' "$SIMCTL_JSON" | ruby -rjson -e '
  devices = JSON.parse(STDIN.read).fetch("devices").values.flatten
  phone = devices.find { |device| device["isAvailable"] && device["name"].start_with?("iPhone") }
  abort "no available iPhone simulator" unless phone
  puts phone.fetch("udid")
')"

xcodebuild test \
  -workspace "$ROOT/RecipeSwipe.xcworkspace" \
  -scheme RecipeSwipe \
  -destination "platform=iOS Simulator,id=$DEVICE_ID" \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  IPHONEOS_DEPLOYMENT_TARGET=12.0
