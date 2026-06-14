# Location-Independent Archived iOS Gates

## Status: Planned

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

## Work Planned

- Add an override-protected absolute repository root to the Makefile.
- Root Ruby structural checks plus conditional XCTest and build recipes.
- Extend the source checker with exact Make and completed-plan contracts.
