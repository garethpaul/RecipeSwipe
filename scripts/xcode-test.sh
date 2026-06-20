#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA="${TMPDIR:-/tmp}/RecipeSwipe-DerivedData"
DEVICE_ID="$(xcrun simctl list devices available -j | ruby -rjson -e '
  devices = JSON.parse(STDIN.read).fetch("devices").values.flatten
  phone = devices.find { |device| device["isAvailable"] && device["name"].start_with?("iPhone") }
  abort "no available iPhone simulator" unless phone
  puts phone.fetch("udid")
')"

rm -rf "$DERIVED_DATA"
xcodebuild test \
  -workspace "$ROOT/RecipeSwipe.xcworkspace" \
  -scheme RecipeSwipe \
  -destination "platform=iOS Simulator,id=$DEVICE_ID" \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  IPHONEOS_DEPLOYMENT_TARGET=12.0
rm -rf "$DERIVED_DATA"
