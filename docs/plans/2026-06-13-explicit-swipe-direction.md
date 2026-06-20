# Explicit Swipe Direction Handling

## Status: Completed

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

- Replaced the catch-all non-Right branch with an explicit Left branch and an
  early fallback return before recipe or card-stack mutation.
- Added a reusable balanced-method structural contract for Right/Left actions,
  fallback return, and stack-advance ordering.
- Added Minitest coverage for valid source, malformed delegates, and eight
  hostile direction/action/order mutations, then wired it into both Make gates.
- Synchronized maintenance, security, vision, and change-log documentation.

## Verification Results

- `ruby scripts/test-swipe-direction-contract.rb` passed 4 tests and 26 assertions.
- `ruby scripts/check-ios-source.rb`, `make structural`, and `make check`
  passed all locally available gates; the full gate truthfully reported
  `xcodebuild unavailable; XCTest suite not run` and
  `xcodebuild unavailable; compile check not run`.
- The hostile gate rejected all nine actual-source and wiring mutations,
  including generic or None direction handling, missing fallback return,
  duplicate cross-direction actions, early card advancement, removed checker
  invocation, removed Make wiring, and incomplete plan status.
- Workflow YAML parsing, exact-base protected-file comparison, added-line secret
  screening, generated-artifact screening, and `git diff --check` passed before
  the shipping commit.
