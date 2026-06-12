# Hosted Structural Validation

Status: Completed

## Context

RecipeSwipe is an archived Swift/iOS 8.2 project using CocoaPods 0.35 and
MDCSwipeToChoose 0.2.1. Building it with a current hosted Xcode would primarily
measure unsupported toolchain drift, while the dependency-free Ruby validator
already checks the maintained source, project, asset, plan, and data-boundary
contracts.

## Work Completed

- Added fixed-runner macOS 15 validation for pushes to `master` and pull
  requests.
- Kept hosted validation structural-only with `make lint`; it does not install
  archived pods or invoke a modern Xcode build against the legacy project.
- Limited the workflow token to read-only contents access and pinned checkout
  to a reviewed commit.
- Made tracked-file inspection fail closed when Git cannot inspect the checkout.
- Extended the structural validator to preserve the runner, permissions,
  action pin, canonical command, and no-build/no-pod boundary.

## Verification

- `ruby scripts/check-ios-source.rb`
- `make lint`
- `make check`
- `git diff --check`
