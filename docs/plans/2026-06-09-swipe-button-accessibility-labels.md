# Swipe Button Accessibility Labels

Status: Completed

## Context

The recipe picker's like and nope controls are image-only buttons. They are
visually clear, but without accessibility labels the controls do not expose
their purpose to VoiceOver or other assistive tooling.

## Objectives

- Add explicit accessibility labels to the like and nope buttons.
- Extend the static iOS source validator so the labels cannot drift silently.
- Keep the guard dependency-free and compatible with the legacy Swift source.
- Document the guard in README, VISION, and CHANGES.

## Work Completed

- Added `button.accessibilityLabel = "Skip recipe"` to the nope button.
- Added `button.accessibilityLabel = "Save recipe"` to the like button.
- Extended `scripts/check-ios-source.rb` to validate both button labels.
- Updated top-level maintenance documentation for the accessibility guard.

## Verification

- `ruby -c scripts/check-ios-source.rb`
- `ruby scripts/check-ios-source.rb`
- `make lint`
- `make test`
- `make build`
- `make check`
- `git diff --check`
