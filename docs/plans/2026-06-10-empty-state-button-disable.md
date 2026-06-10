# Empty-State Swipe Button Disable

## Status: Completed

## Context

Like and skip taps were safely ignored after the recipe stack became an empty
placeholder, but both image-only buttons remained enabled. The empty state
therefore exposed controls that appeared actionable visually and to VoiceOver
even though no recipe could be saved or skipped.

## Objectives

- Disable like and skip controls whenever no `RecipePickerView` is active.
- Keep both controls enabled while a recipe card is available.
- Synchronize state after button construction and every card-stack promotion.
- Preserve the existing guarded swipe helper and legacy Swift syntax.

## Work Completed

- Retained optional references to the like and skip buttons.
- Added `updateSwipeButtonsEnabled()` based on the active top-card type.
- Synchronized each button during construction and after swipe delegate card
  promotion.
- Extended the dependency-free Ruby source validator and documentation.

## Verification

- `ruby -c scripts/check-ios-source.rb`
- `make lint`
- `make check`
- Removed one enabled-state assignment in a mutation check and confirmed the
  structural validator rejected the change.
- `git diff --check`

XCTest and compile verification were not run locally because `xcodebuild` is
unavailable and this project targets an archived Swift/iOS toolchain.
