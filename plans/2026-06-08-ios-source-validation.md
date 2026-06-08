# iOS Source Validation

## Problem

The project is a legacy Xcode/CocoaPods app, but the current Linux environment
does not provide `xcodebuild`, `swift`, or `pod`. The repository still needs a
repeatable quality gate that catches source and project-file regressions before
changes are pushed.

## TDD Evidence

1. Added `scripts/check-ios-source.rb` and `make lint`.
2. Ran the validator before source fixes and confirmed it failed on:
   - Swift files using `UIImage` without importing UIKit.
   - A `UIImage(named: "photo.jpg")` reference that does not match the asset
     catalog name.
   - Absolute `SWIFT_OBJC_BRIDGING_HEADER` paths in the Xcode project.
3. Fixed the source and project settings, then reran the gate.

## Verification

- `make lint`
- `make test`
- `make verify`
- `git diff --check`

`make verify` runs `xcodebuild` when Xcode is installed and otherwise reports
that only the static iOS checks were available in this environment.
