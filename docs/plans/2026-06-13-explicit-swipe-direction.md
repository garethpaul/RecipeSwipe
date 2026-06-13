# Explicit Swipe Direction Handling

## Status: Pending

## Context

The vendored `MDCSwipeDirection` enum includes `None`, `Left`, and `Right`.
`RecipePickerViewController` saves on Right but treats every other value as
Left, so a defensive or manually invoked `None` delegate callback can skip a
recipe and advance the card stack without an actual choice.

## Objectives

- Save recipes only for `MDCSwipeDirection.Right`.
- Skip recipes only for `MDCSwipeDirection.Left`.
- Return before recipe mutation or card-stack advancement for `None` or any
  unsupported direction value.
- Preserve existing guarded view casting, button synchronization, card
  animation, and valid swipe behavior.
- Add a reusable structural contract and hostile mutation coverage.

## Scope Boundaries

- Do not modify vendored `Pods/` code or the direction enum.
- Do not change button actions, swipe thresholds, recipe persistence, or card
  ordering for valid Left and Right choices.
- Do not claim Xcode compilation or XCTest on the Linux host.
- Preserve the archived Swift/iOS 8.2 syntax and dependency baseline.

## Verification

- `ruby scripts/check-ios-source.rb`
- `ruby scripts/test-swipe-direction-contract.rb`
- `make structural` and `make check`
- hostile mutations covering the Left condition, None fallback, early return,
  stack-advance ordering, documentation, completed status, and evidence
- workflow parse, exact-base protected-file, secret, generated-artifact, and
  `git diff --check` gates

## Work Completed

Pending implementation.

## Verification Results

Pending implementation and validation.
