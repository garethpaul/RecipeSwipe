# Safe Makefile Root Resolution

## Status: Completed

## Context

Caller-controlled root and shell authority, preloaded or ambiguous Makefiles,
and shell-sensitive checkout names could redirect or execute Ruby structural
checks, SwiftPM, XCTest, and Xcode commands outside the reviewed checkout.

## Scope Boundaries

- Do not change app behavior, swipe state, Swift source, Xcode settings, assets,
  CocoaPods, deployment targets, or signing assumptions.
- Preserve truthful non-macOS toolchain failures and hosted macOS validation.
- Keep the regression suite independent of Xcode and Swift.

## Work Completed

- Reject command-line and environment replacement of `MAKEFILE_LIST`.
- Canonicalize the checked-in Makefile directory through quoted POSIX tools.
- Freeze shell authority, export the canonical root as data, and reject
  `MAKEFILES` preloads and ambiguous multiple-`-f` invocations.
- Add coverage for all seven pre-existing public Make targets plus the root regression gate.
- Include the root policy in `make verify` and `make check`.

## Verification Completed

- Linux structural checks, asset contracts, swipe-state mutations, Xcode runner
  contracts, workflow mutations, and root tests passed.
- All 56 executed target, root, shell, and shell-flag authority cases passed
  from a path containing spaces, quotes, brackets, an apostrophe, and backticks.
- Both `MAKEFILE_LIST` override channels, a `MAKEFILES` preload, and an
  ambiguous multiple-Makefile invocation failed closed.
- Native SwiftPM, XCTest, and Xcode execution remains hosted-macOS validation.
