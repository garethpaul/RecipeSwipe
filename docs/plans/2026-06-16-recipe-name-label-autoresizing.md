# Recipe Name Label Autoresizing

## Status: Completed

## Context

`RecipePickerView` allows the card and its information strip to resize, but the
recipe name label keeps its original frame. A width or height change can
therefore leave the label narrower or shorter than its container.

## Objectives

- Make the recipe name label follow both width and height changes in its info
  container.
- Add a focused static contract with hostile mutations for missing or partial
  autoresizing behavior.
- Keep the archived Swift syntax, public behavior, and Linux/Xcode validation
  boundary unchanged.

## Scope Boundaries

- Do not modernize Swift, UIKit, CocoaPods, project settings, or deployment
  targets.
- Do not change card sizing, typography, recipe data, gesture behavior, or
  navigation.
- Do not claim simulator rendering, XCTest, or compilation on the Linux host.

## Verification

- focused name-label layout contract tests
- repository-root and external-directory `make check`
- hostile mutations for missing width, missing height, wrong target, and
  overwritten autoresizing masks
- exact diff, generated-artifact, secret-like addition, and worktree audits

## Work Completed

- Added width and height autoresizing to the recipe name label before it is
  attached to its resizing info container.
- Added a standalone static contract and wired its focused tests into every
  portable Make test lane.
- Documented the layout invariant in the README maintenance baseline.

## Verification Results

- The focused contract passed 4 tests and 19 assertions.
- Five actual-source hostile mutations were rejected for missing width, missing
  height, wrong target, mask overwrite, and post-attachment configuration.
- Repository-root and external-directory `make check` both passed iOS source
  validation, 11 asset tests with 33 assertions, 4 name-label tests with 19
  assertions, 5 pan-state tests with 24 assertions, 4 swipe-direction tests
  with 26 assertions, and 13 workflow mutations.
- The Linux host truthfully reported `xcodebuild unavailable; XCTest suite not run`
  and `xcodebuild unavailable; compile check not run` in both full gates.
