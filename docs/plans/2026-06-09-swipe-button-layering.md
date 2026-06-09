# Swipe Button Layering

## Status: Completed

## Context

The legacy recipe picker renders an empty-state image and label behind the card
stack when local sample recipes run out. The like and nope buttons were inserted
at subview index `0`, which can place them behind the empty-state artwork and
make the controls harder to see or tap.

## Objectives

- Keep the existing like and nope button styling and actions.
- Add swipe buttons above background artwork instead of behind it.
- Add deterministic static validation for the expected layering pattern.
- Avoid unrelated Swift modernization in this focused pass.

## Work Completed

- Changed `constructNopeButton()` and `constructLikeButton()` to add their
  controls above existing background subviews.
- Extended `scripts/check-ios-source.rb` to reject button insertion at subview
  index `0` for the swipe controls.
- Updated README, VISION, and CHANGES notes for the layering guard.

## Verification

- `ruby scripts/check-ios-source.rb`
- `make lint`
- `make check`
- `make verify`
- `git diff --check`

## Xcode Notes

Xcode was not available in this environment, so simulator interaction testing
was not run here. The repository `make check` wrapper still runs `xcodebuild`
when that tool is available locally.
