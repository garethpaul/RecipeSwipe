#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRATCH="${TMPDIR:-/tmp}/RecipeSwipe-SPM"

rm -rf "$SCRATCH"
swift test --package-path "$ROOT" --scratch-path "$SCRATCH"
rm -rf "$SCRATCH"
