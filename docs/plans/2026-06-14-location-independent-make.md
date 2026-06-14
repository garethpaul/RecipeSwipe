# Location-Independent Archived iOS Gates

## Status: Completed

## Context

The Make recipes resolve Ruby validators, the Xcode workspace, and the scheme
in the caller's current directory. Invoking the repository Makefile through an
absolute path from another directory therefore cannot reproduce the archived
iOS structural gate.

## Objectives

- Resolve the repository root from the loaded Makefile.
- Run every Ruby and Xcode recipe from that root, independent of the caller.
- Protect the root and all distinct rooted recipe classes with
  mutation-sensitive structural contracts.
- Preserve structural validation and truthful Xcode/XCTest skip behavior.

## Scope Boundaries

- Do not change Swift behavior, Xcode settings, CocoaPods dependencies, vendored
  Pods, signing, simulator selection, or hosted workflow coverage.
- Do not claim Xcode compilation or XCTest on the Linux host.

## Verification

- every Make alias from the repository root and an unrelated directory
- `make structural` and `make check` with the existing Xcode skip boundary
- hostile mutations covering root derivation and every distinct rooted recipe
  class
- exact-base Swift, project, workspace, Pod, dependency, workflow, secret,
  captured-prompt, and generated-artifact scans
- `git diff --check`

## Work Completed

- Added an override-protected absolute repository root to the Makefile.
- Rooted Ruby structural checks plus conditional XCTest and build recipes.
- Extended the source checker with exact Make and completed-plan contracts.

## Verification Results

- Every Make alias passed from both the repository root and an unrelated
  directory with `REPO_ROOT=/tmp` supplied on the command line.
- Eight hostile mutations rejected removal of override protection, lint
  rooting, each structural-script class, the XCTest root, and the build root.
- Asset contracts passed 11 tests and 33 assertions, pan-state contracts passed
  5 tests and 24 assertions, swipe-direction contracts passed 4 tests and 26
  assertions, and workflow contracts rejected 13 mutations.
- The Linux host truthfully reported `xcodebuild unavailable; XCTest suite not run`
  and `xcodebuild unavailable; compile check not run`.
- Exact-base checks preserved Swift sources and tests, project and workspace,
  Pod manifests, vendored Pods, and workflow; no generated Apple artifacts
  remained.
- `git diff --check` and secret, captured-prompt, dependency, workflow, and
  generated-artifact scans passed.
