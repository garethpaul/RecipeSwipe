# Recipe Optional Unwrapping

## Status: Completed

## Context

`RecipePickerView` and related view controllers still force-unwrapped optional
`Recipe` references after earlier hardening made placeholder cards and
delegate callbacks safe. A missing recipe should leave the prototype UI empty
or no-op rather than crashing.

## Objectives

- Replace forced `recipe!` accesses with guarded optional binding.
- Keep the existing save, skip, and display behavior unchanged when recipes are
  present.
- Add deterministic static validation so Swift source cannot reintroduce
  forced recipe optional unwraps.

## Work Completed

- Extended `scripts/check-ios-source.rb` to reject `recipe!` in Swift source.
- Guarded recipe saves, skips, card labels, and detail image loading with
  `if let` optional binding.
- Updated README, VISION, and CHANGES notes for the recipe optional guard.

## Verification

- `ruby scripts/check-ios-source.rb`
- `make check`
- `make verify`
- `git diff --check`

## Xcode Notes

XcodeBuildMCP tools were not available in this Codex session, so simulator
automation was not run here. The repository `make check` wrapper still runs
`xcodebuild` when that tool is available locally.
