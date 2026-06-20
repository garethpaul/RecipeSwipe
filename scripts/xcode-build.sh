#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA="${TMPDIR:-/tmp}/RecipeSwipe-Build"

rm -rf "$DERIVED_DATA"
xcodebuild build \
  -workspace "$ROOT/RecipeSwipe.xcworkspace" \
  -scheme RecipeSwipe \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  IPHONEOS_DEPLOYMENT_TARGET=12.0
rm -rf "$DERIVED_DATA"
