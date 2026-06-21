# Safe Makefile Root Resolution

## Status: Completed

## Context

Caller-controlled `MAKEFILE_LIST` redirected Ruby structural checks, SwiftPM,
XCTest, and Xcode commands outside the reviewed checkout.

## Scope Boundaries

- Do not change app behavior, swipe state, Swift source, Xcode settings, assets,
  CocoaPods, deployment targets, or signing assumptions.
- Preserve truthful non-macOS toolchain failures and hosted macOS validation.
- Keep the regression suite independent of Xcode and Swift.

## Work Completed

- Reject command-line and environment replacement of `MAKEFILE_LIST`.
- Canonicalize the checked-in Makefile directory through quoted POSIX tools.
- Add coverage for all seven pre-existing public Make targets plus the root regression gate.
- Include the root policy in `make verify` and `make check`.

## Verification Completed

- Linux structural checks, asset contracts, swipe-state mutations, Xcode runner
  contracts, workflow mutations, and root tests passed.
- All 24 target and `REPO_ROOT` override cases passed from a shell-sensitive path.
- Command-line and environment `MAKEFILE_LIST` overrides failed closed.
- Native SwiftPM, XCTest, and Xcode execution remains hosted-macOS validation.
