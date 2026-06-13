# Repository-Wide Swipe Pan-State Guards

## Status: Completed

## Context

The archived `MDCSwipeToChoose` Objective-C bridge exposes pan callback state
as `MDCPanState!`. The active recipe picker now unwraps that value, but the
legacy `ViewController` example still reads `state.thresholdRatio` and
`state.direction` directly. A nil callback can therefore terminate that scene.

## Priority

Nullable bridge values are an app-stability boundary. Every tracked `onPan`
callback should ignore missing state rather than relying on an implicitly
unwrapped optional, and the structural gate should prevent a future callback
from reintroducing the same crash pattern elsewhere.

## Objectives

- Guard the remaining `ViewController` pan callback before property access.
- Preserve its left-swipe logging behavior for valid callback state.
- Generalize structural validation to inspect every Swift `onPan` callback.
- Add hostile mutation coverage for missing guards and direct nullable access.
- Record the archived-toolchain verification boundary truthfully.

## Work Completed

- Added optional binding to the remaining `ViewController` pan callback.
- Added a reusable contract that inspects every tracked Swift `onPan` closure.
- Added focused tests covering typed and inferred callbacks, nested blocks,
  multiple callbacks, missing guards, direct dereferences, and misplaced guards.
- Wired the mutation suite into both structural and full verification targets.
- Updated maintenance documentation to describe repository-wide enforcement.

## Verification

- `ruby scripts/check-ios-source.rb`
- `ruby scripts/test-pan-state-contract.rb`
- `make structural`
- `make check`
- Focused hostile mutations of both callback implementations
- `git diff --check`

The focused contract suite passed 24 assertions and rejected six hostile
nullable-state mutations. `make check` completed successfully; on this Linux
host it truthfully reported that Xcode compilation and XCTest were not run.

## Xcode Boundary

`xcodebuild` is unavailable on this Linux host. Local validation can prove the
source and structural contracts, but it cannot claim simulator compilation or
XCTest execution for this archived Swift and iOS 8.2 project.
