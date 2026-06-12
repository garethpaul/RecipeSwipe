# Swipe Pan-State Optional Guard

## Status: Completed

## Context

The archived `MDCSwipeToChoose` callback exposes its pan state as
`MDCPanState!`. `RecipePickerViewController` immediately reads
`state.thresholdRatio`, so an Objective-C callback that supplies nil would
terminate the app before the card stack can recover.

## Priority

The callback crosses an Objective-C bridge and is explicitly nullable in the
legacy Swift signature. The app should ignore a malformed pan update rather
than crash while preserving normal card animation for valid states.

## Objectives

- Guard the implicitly unwrapped pan state before reading its properties.
- Preserve the existing bottom-card animation for valid callbacks.
- Add a fail-closed structural source contract for the optional binding.
- Document the behavior and archived-toolchain verification boundary.

## Work Completed

- Guarded the `MDCPanState!` callback with optional binding before reading
  animation progress.
- Added a method-scoped structural contract that requires the binding and
  rejects direct `state.thresholdRatio` access.
- Updated maintenance documentation and the archived-project roadmap.

## Verification

- `ruby scripts/check-ios-source.rb`
- `make structural`
- `make check`
- A focused hostile mutation restored direct `state.thresholdRatio` access
  without optional binding; the source checker rejected both the missing guard
  and the nullable dereference.
- `git diff --check`

## Xcode Notes

`xcodebuild` is unavailable on this Linux host, so simulator compilation and
XCTest cannot be claimed locally. The hosted repository gate remains structural
because this project targets archived Swift and iOS 8.2 tooling.
