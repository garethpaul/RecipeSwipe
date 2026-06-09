# Swipe Delegate Type Guard

## Status: Completed

## Context

`RecipePickerViewController` receives chosen card callbacks through the
`MDCSwipeToChooseDelegate` Objective-C bridge. The callback argument is typed as
`UIView!`, but the implementation force-cast it to `RecipePickerView` before
saving, skipping, or advancing cards. A stray callback with a placeholder view
or another view type should not crash the prototype.

## Objectives

- Keep save, skip, and card-advance behavior unchanged for real recipe cards.
- Ignore delegate callbacks that are not backed by `RecipePickerView`.
- Add deterministic static validation for the guarded delegate cast.
- Avoid broader Swift modernization in this focused pass.

## Work Completed

- Replaced the swipe delegate force-cast with an optional `RecipePickerView`
  guard.
- Extended `scripts/check-ios-source.rb` to reject the old force-cast and
  require the guarded delegate pattern.
- Updated README, VISION, and CHANGES notes for the delegate type guard.

## Verification

- `ruby scripts/check-ios-source.rb`
- `make check`
- `make verify`
- `git diff --check`

## Xcode Notes

`xcodebuild` was not available in this environment, so simulator-backed XCTest
coverage was not run here. The repository `make check` wrapper still runs
`xcodebuild` when that tool is available locally.
