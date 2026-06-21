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
- GNU Make can execute parse-time expressions in caller-supplied preloaded or
  additional Makefiles before this repository's guard runs; trusted automation
  must not supply them. Runtime tool identities also remain the responsibility
  of the trusted caller's `PATH`.
- This is a checked-in Makefile boundary, not a sandbox for caller programs.
  GNU Make `override` directives, caller-added double-colon recipes, and
  startup parse-time code retain Make-level authority and remain outside the
  local no-execution claim.

## Work Completed

- Reject command-line and environment replacement of `MAKEFILE_LIST`.
- Canonicalize the checked-in Makefile directory through quoted POSIX tools.
- Freeze shell authority, export the canonical root as data, and reject
  `MAKEFILES` preloads, later single-colon recipe replacement, and the `-n`,
  `-t`, `-q`, and `-i` Make modes that skip or ignore verification recipes,
  including command-line replacement of the `MAKEFLAGS` evidence.
- Define all eight public aliases as double-colon rules so a later file cannot
  combine `REPOSITORY_MAKEFILE` replacement with single-colon replacement of
  every repository recipe. The combined eight-recipe bypass fails during Make
  parsing before any attacker marker or quality command executes.
- Pin `/bin/sh -c` target-specifically and embed the reviewed checkout root in
  repository recipes so later non-override target-specific variables cannot
  intercept the guard or redirect quality commands.
- Use absolute root-resolution tools so caller `PATH` entries cannot replace
  `sed`, `dirname`, or `pwd` while the checkout location is established.
- Add coverage for all seven pre-existing public Make targets plus the root regression gate.
- Include the root policy in `make verify` and `make check`.

## Verification Completed

- Linux structural checks, asset contracts, swipe-state mutations, Xcode runner
  contracts, workflow mutations, and root tests passed.
- All 56 executed target, root, shell, and shell-flag authority cases passed
  from a path containing spaces, quotes, brackets, an apostrophe, a semicolon,
  and backticks without invoking caller-shadowed root tools.
- Both `MAKEFILE_LIST` override channels, a `MAKEFILES` preload, earlier
  additional-file rejection, later single-colon replacement including the
  combined eight-recipe bypass, four non-executing or error-ignoring
  `MAKEFLAGS` modes, and command-line `MAKEFLAGS` replacement failed closed.
- A literal `$()` checkout path failed closed without executing its contents;
  GNU Make removes that segment from `MAKEFILE_LIST`, so safe reconstruction is
  unavailable.
- Native SwiftPM, XCTest, and Xcode execution remains hosted-macOS validation.
