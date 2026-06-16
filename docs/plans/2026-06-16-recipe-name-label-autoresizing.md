# Recipe Name Label Autoresizing

## Status: In Progress

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

