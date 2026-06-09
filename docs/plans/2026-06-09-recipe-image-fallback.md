# Recipe Image Fallback

## Status: Completed

## Context

The local recipe fixture loaded sample card images with forced
`UIImage(named:)` unwraps. The asset catalog validator catches missing asset
names, but the runtime path should still avoid crashing before the picker has a
chance to render a placeholder-safe card stack.

## Objectives

- Keep the local sample recipe data and card contents unchanged.
- Replace forced image unwraps with a checked fallback image path.
- Add deterministic static validation so fixture image loads stay guarded.
- Avoid broad Swift modernization in this focused pass.

## Work Completed

- Added an `APIClient.sampleRecipeImage()` helper that returns the `photo`
  catalog image when available and an empty `UIImage` fallback otherwise.
- Reused that checked sample image for the local recipe fixtures.
- Extended `scripts/check-ios-source.rb` to reject forced `UIImage(named:)`
  unwraps in Swift source.
- Updated README, VISION, and CHANGES notes for the image fallback guard.

## Verification

- `ruby scripts/check-ios-source.rb`
- `make check`
- `git diff --check`

## Xcode Notes

XcodeBuildMCP was not available in this environment, so simulator screenshot
verification was not run here. The repository `make check` wrapper still runs
`xcodebuild` when that tool is available locally.
