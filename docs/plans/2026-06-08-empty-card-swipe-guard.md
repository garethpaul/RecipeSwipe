# Empty Card Swipe Guard

## Status: Completed

## Context

`RecipeSwipe` defers initial card setup until local recipe data is fetched, but
the like and skip buttons still sent swipe actions directly to `topCardView`.
Once recipes run out, `topCardView` can be an empty placeholder `UIView`, so
button actions should guard that the current top card is actually swipeable.

## Objectives

- Keep the legacy card swipe behavior unchanged when a real recipe card is on
  top.
- Ignore like/skip button taps when the top card is only an empty placeholder.
- Extend static source validation to catch direct unguarded top-card swipes.
- Validate every completed plan under `docs/plans` from `make check`.

## Work Completed

- Added `swipeTopCard(direction:)` with a `RecipePickerView` conditional cast.
- Updated like and skip button actions to call the guarded helper.
- Extended `scripts/check-ios-source.rb` to validate all docs plans and the
  guarded top-card swipe pattern.
- Updated README, VISION, and CHANGES.

## Verification

- `ruby scripts/check-ios-source.rb`
- `make check`
- `make verify`
- `git diff --check`

## Follow-Up Candidates

- Add simulator-backed XCTest coverage for the empty-recipes state when Xcode
  is available.
- Document the intended persistence path for liked recipes before replacing the
  in-memory array.
