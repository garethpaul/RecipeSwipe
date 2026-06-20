# Swipe lifecycle deep review

Status: Completed

## Scope

Deep-review PRs #1-#6 and the adjacent archived iOS swipe path, including nullable callbacks, direction thresholds, duplicate completions, deck exhaustion, animation ownership, malformed data, accessibility, Xcode integrity, and CI policy.

## Root cause and provenance

The original 2014 controller directly removed array elements and replaced mutable `topCardView`/`bottomCardView` placeholders from delegate callbacks. It did not bind callbacks to a card identity or generation, did not own an in-flight transition, and could therefore process stale or duplicate callbacks against a newer deck state. The stacked PRs added useful nil and direction guards but retained that ownership model.

## Fix

- Added `SwipeDeck` generation tokens and bounded indexing.
- Required active-view identity and one in-flight transition before consuming a card.
- Validated finite, aligned translation or velocity against explicit thresholds.
- Captured newly inserted views immutably during animation.
- Sanitized and bounded recipe names.
- Added Dynamic Type, multiline names, card action hints, and button accessibility.
- Modernized Swift/Xcode settings and made all gates location-independent.

## Evidence

- `make check` passed from `/tmp`.
- 4 SwiftPM tests and 4 native XCTest cases passed.
- 11 asset tests passed.
- 12 hostile swipe-state mutations and 13 workflow mutations were rejected.
- Generic iOS Simulator build passed for arm64 and x86_64.
- Hosted Check and CodeQL evidence is required on the consolidation PR before merge.
