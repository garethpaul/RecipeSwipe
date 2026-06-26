# RecipeSwipe Persistence Path

## Status: Completed

## Context

RecipeSwipe currently appends right-swiped `Recipe` objects to a private
process-memory array. The initial 2014 implementation marked both save and skip
handling with a Core Data TODO, and the maintained roadmap still asks for the
intended persistence path. The current `Recipe` model has only a normalized
name and a runtime `UIImage`, while `APIClient` supplies hardcoded local recipes
and one bundled image asset.

Apple documents Core Data as a local object-graph and persistence framework,
with model versioning and migration support. That matches the repository's
original intent without introducing a network service, CloudKit, or a new
third-party dependency.

## Decision

- Keep the current app behavior process-memory-only until persistence is
  implemented and tested in a separate change.
- Use a local Core Data SQLite store behind a narrow `SavedRecipeStore`
  protocol when the feature is implemented.
- Add a stable recipe identifier before persistence; normalized display names
  are not unique identities.
- Persist metadata such as recipe ID, normalized name, image asset key, and
  saved timestamp rather than archiving `UIImage` instances.
- Make saving idempotent by recipe ID and define removal as an explicit future
  action rather than treating a later left swipe as deletion.
- Load saved recipes independently from the active swipe deck so persistence
  cannot alter deck-consumption or gesture ownership rules.
- Keep the first store local-only. CloudKit, accounts, remote recipe fetching,
  and cross-device synchronization require separate contracts.
- Version the managed object model from its first release and exercise an
  in-memory store in repository tests before enabling disk persistence.

## Test First

Extend the portable Ruby validator to require the persistence document, its
current-state warning, the Core Data boundary, stable identity, metadata-only
image policy, idempotent save rule, local-only scope, and in-memory test plan.
Run the validator before adding the document; it must fail on the missing
contract.

## Verification Plan

- Run `ruby scripts/check-ios-source.rb` before and after documentation.
- Run `make lint`, `structural`, `core-test`, and `root-test` locally.
- Run `make test`, `build`, `verify`, and `check` when the Apple simulator and
  Xcode toolchain are available; otherwise record the blocked native gate.
- Run Ruby syntax checks and `git diff --check`.
- Use hosted macOS structural, simulator, build, and CodeQL checks as exact-head
  authority.

## Scope Boundaries

- No `.xcdatamodeld`, Core Data stack, store protocol, UI, segue, recipe model,
  swipe behavior, asset, dependency, project-file, or runtime change.
- No claim that liked recipes survive relaunch in the current app.
- No production choice between generated and handwritten managed-object types;
  that belongs with the implementation and its supported Xcode baseline.

## Verification Completed

- The red-first Ruby contract failed on seven missing design guarantees plus
  missing roadmap, history, and completed-plan evidence.
- The completed `ruby scripts/check-ios-source.rb` contract passed in Ruby 3.3.
- `make lint`, `structural`, `core-test`, and `root-test` passed from the
  checkout and through the absolute Makefile path from `/tmp` in a Swift 6.0
  and Ruby container.
- Portable evidence included 11 asset tests, 23 rejected swipe-state mutations,
  13 rejected workflow mutations, 7 Swift tests, Xcode-runner contracts, and 56
  Make authority cases.
- Full `make check` reached the expected native Linux boundary when `xcrun` was
  unavailable; hosted macOS remains responsible for XCTest and simulator build
  evidence.
- Ruby and shell syntax checks plus `git diff --check` passed.
