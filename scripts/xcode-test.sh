#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA="$(mktemp -d "${TMPDIR:-/tmp}/RecipeSwipe-DerivedData.XXXXXX")"
RESULT_DIRECTORY="$(mktemp -d "${TMPDIR:-/tmp}/RecipeSwipe-TestResults.XXXXXX")"
RESULT_BUNDLE="$RESULT_DIRECTORY/RecipeSwipeTests.xcresult"
SIMCTL_OUTPUT="$(mktemp "${TMPDIR:-/tmp}/RecipeSwipe-Simctl.XXXXXX")"
SIMCTL_ATTEMPT_TIMEOUT="${RECIPESWIPE_SIMCTL_TIMEOUT:-20}"
SIMCTL_ATTEMPTS=3
XCODEBUILD_TIMEOUT="${RECIPESWIPE_XCODEBUILD_TIMEOUT:-600}"
XCRUN="${XCRUN:-xcrun}"
XCODEBUILD="${XCODEBUILD:-xcodebuild}"
WATCHDOG_PID=""
DEVICE_ID=""

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

select_simulator_device() {
  ruby --disable-gems -rjson -e '
    begin
      devices = JSON.parse(STDIN.read).fetch("devices").values.flatten
    rescue JSON::ParserError, KeyError, NoMethodError => error
      warn "malformed simulator discovery response: #{error.message}"
      exit 1
    end

    phone = devices.find { |device| device["isAvailable"] && device["name"].start_with?("iPhone") }
    unless phone
      warn "no available iPhone simulator"
      exit 0
    end

    udid = phone["udid"]
    unless udid.is_a?(String) && !udid.empty?
      warn "malformed simulator discovery response: selected iPhone is missing a udid"
      exit 1
    end

    puts udid
  ' < "$SIMCTL_OUTPUT"
}

discover_simulator() {
  local attempt
  local exit_code
  local selected_device

  for ((attempt = 1; attempt <= SIMCTL_ATTEMPTS; attempt += 1)); do
    if run_with_timeout "$SIMCTL_ATTEMPT_TIMEOUT" "simctl list devices" "$XCRUN" simctl list devices available -j > "$SIMCTL_OUTPUT"; then
      if selected_device="$(select_simulator_device)"; then
        if [[ -n "$selected_device" ]]; then
          DEVICE_ID="$selected_device"
          return 0
        fi

        if [[ "$attempt" -eq "$SIMCTL_ATTEMPTS" ]]; then
          return 124
        fi

        printf 'simctl list devices found no available iPhone on attempt %d/%d; retrying simulator discovery\n' "$attempt" "$SIMCTL_ATTEMPTS" >&2
        continue
      else
        return "$?"
      fi
    else
      exit_code=$?
    fi

    if [[ "$exit_code" -ne 124 || "$attempt" -eq "$SIMCTL_ATTEMPTS" ]]; then
      return "$exit_code"
    fi

    printf 'simctl list devices timed out on attempt %d/%d; retrying simulator discovery\n' "$attempt" "$SIMCTL_ATTEMPTS" >&2
  done
}

trap cleanup EXIT
trap 'handle_signal HUP' HUP
trap 'handle_signal INT' INT
trap 'handle_signal TERM' TERM

discover_simulator

run_with_timeout "$XCODEBUILD_TIMEOUT" "xcodebuild test" "$XCODEBUILD" test \
  -workspace "$ROOT/RecipeSwipe.xcworkspace" \
  -scheme RecipeSwipe \
  -destination "platform=iOS Simulator,id=$DEVICE_ID" \
  -derivedDataPath "$DERIVED_DATA" \
  -resultBundlePath "$RESULT_BUNDLE" \
  CODE_SIGNING_ALLOWED=NO \
  IPHONEOS_DEPLOYMENT_TARGET=12.0
