# Local Recipe Data Guard

## Status: Completed

## Context

`RecipeSwipe` is currently a local prototype with hardcoded sample recipes.
The project vision explicitly keeps recipe fetching local and fake until a data
contract is documented, but the static validator did not fail if Swift source
introduced network request APIs or URL literals.

## Objectives

- Keep validation independent of Xcode and CocoaPods.
- Fail when Swift source introduces network recipe-data markers before a data
  contract exists.
- Preserve the existing UIKit import, asset, Pods, bridging-header, and empty
  card swipe checks.
- Record the guard under `docs/plans`.

## Work Completed

- Extended `scripts/check-ios-source.rb` to scan Swift source for network API
  markers and URL literals.
- Added this completed plan under `docs/plans/`.
- Updated README, VISION, and CHANGES notes for the local recipe-data guard.

## Verification

- `ruby scripts/check-ios-source.rb`
- `make check`
- `make verify`
- `git diff --check`
