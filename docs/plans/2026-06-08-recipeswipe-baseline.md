# RecipeSwipe Baseline

## Status: Completed

## Context

`RecipeSwipe` is a legacy Swift/CocoaPods iOS prototype for swiping through
local sample recipe cards. Recent maintenance added static source validation,
fixed UIKit import and asset lookup issues, removed a machine-local bridging
header path, and deferred initial card setup until sample data is loaded.

## Objectives

- Preserve the local swipe-card prototype behavior.
- Keep recipe data local and fake until a data contract is documented.
- Validate UIKit imports, asset catalog references, CocoaPods lockfile
  consistency, bridging-header paths, and deferred card loading without
  requiring Xcode.
- Run Xcode build and test commands when the toolchain is available.
- Record the completed baseline under `docs/plans`.

## Work Completed

- Added `scripts/check-ios-source.rb` and `make check`.
- Added validator coverage for the deferred card-loading sequence.
- Extended the validator to require this canonical completed plan.
- Updated README, VISION, and CHANGES with the canonical plan location.

## Verification

- `make check`
- `make verify`
- `ruby scripts/check-ios-source.rb`
- `git diff --check`

## Follow-Up Candidates

- Document Xcode, CocoaPods, and simulator expectations in more detail.
- Modernize Swift syntax in a dedicated compatibility pass.
- Add simulator-level interaction tests when an iOS toolchain is available.
