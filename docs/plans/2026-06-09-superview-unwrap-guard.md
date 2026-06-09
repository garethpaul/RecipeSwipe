# Superview Unwrap Guard

## Status: Completed

## Context

The legacy swipe sample cancelled right swipes by snapping the card back to
`view.superview!.center`. That works while the card remains attached to a
parent view, but it can crash if the animation runs after the view has been
detached.

## Objectives

- Replace the forced `superview!` access with guarded optional binding.
- Preserve the existing snap-back animation when the card still has a parent.
- Extend static validation so Swift source cannot reintroduce `superview!`.

## Work Completed

- Guarded `ViewController`'s cancelled-swipe animation before reading the
  parent view center.
- Extended `scripts/check-ios-source.rb` to reject `superview!` in Swift
  source.
- Updated README, VISION, and CHANGES notes for the superview unwrap guard.

## Verification

- `ruby scripts/check-ios-source.rb`
- `make check`
- `make verify`
- `git diff --check`

## Xcode Notes

XcodeBuildMCP tools were not available in this Codex session, so simulator
automation was not run here. The repository `make check` wrapper still runs
`xcodebuild` when that tool is available locally.
