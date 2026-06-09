# Empty-State Background Sizing

## Status: Completed

## Context

When local recipe data runs out, `RecipePickerViewController` renders an
empty-state frown image and label behind the card stack. The image frame used
the bottom card width for both width and height, which could make the
empty-state artwork square even when the active card frame is not.

## Objectives

- Keep the legacy empty-state UI behavior intact.
- Size the empty-state image height from `bottomCardView.frame` height.
- Add a deterministic static guard for the expected frame calculation.
- Avoid broad Swift syntax modernization in this focused pass.

## Work Completed

- Updated `constructBackground()` to use `CGRectGetHeight(bottomCardView.frame)`
  for the frown image height.
- Extended `scripts/check-ios-source.rb` to validate the empty-state background
  sizing pattern and reject the old width-as-height calculation.
- Updated README, VISION, and CHANGES notes for the layout guard.
- Added this completed plan under `docs/plans/`.

## Verification

- `ruby scripts/check-ios-source.rb`
- `make check`
- `make verify`
- `git diff --check`

## Xcode Notes

XcodeBuildMCP was not available in this environment, so simulator screenshot
verification was not run here. The repository `make check` wrapper still runs
`xcodebuild` when that tool is available locally.
