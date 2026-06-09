# RecipeSwipe

<!-- README-OVERVIEW-IMAGE -->
![Project overview](docs/readme-overview.svg)

## Overview

`garethpaul/RecipeSwipe` is an Apple platform application or Objective-C/Swift sample. The "tinder style" swiping for recipes.

This README is based on the checked-in source, manifests, scripts, and repository metadata on the `master` branch. The project language mix found during review was: Swift (8), C/C++ headers (1).

## Repository Contents

- `Podfile` - Apple platform dependency metadata
- `Podfile.lock` - Apple platform dependency metadata
- `RecipeSwipe` - source or example code
- `RecipeSwipe.xcodeproj` - Xcode project file
- `RecipeSwipeTests` - source or example code
- `CHANGES.md` - notable maintenance changes
- `Makefile` - local verification entry points
- `docs/plans` - canonical completed maintenance plans
- `plans` - completed maintenance plans
- `scripts` - deterministic static iOS validation checks
- `SECURITY.md` - security reporting and disclosure guidance
- `VISION.md` - project direction and maintenance guardrails

Additional scan context:

- Source directories: RecipeSwipe, RecipeSwipeTests
- Dependency and build manifests: Podfile, Podfile.lock
- Entry points or build surfaces: RecipeSwipe.xcodeproj
- Test-looking files: RecipeSwipeTests/Info.plist, RecipeSwipeTests/RecipeSwipeTests.swift

## Getting Started

### Prerequisites

- Git
- macOS with Xcode for building Apple platform projects
- CocoaPods if dependencies need to be installed

### Setup

```bash
git clone https://github.com/garethpaul/RecipeSwipe.git
cd RecipeSwipe
pod install
```

The setup commands above are derived from repository files. Legacy mobile, Python, or JavaScript samples may require older SDKs or package versions than a modern workstation uses by default.

## Running or Using the Project

- Open `RecipeSwipe.xcodeproj` in Xcode, choose the app or sample scheme, and run it on the matching simulator/device.

## Testing and Verification

- Xcode's test action or `xcodebuild test` with the appropriate scheme and destination
- `make check` runs static iOS source checks and uses `xcodebuild` when it is
  available locally.
- The static validator also requires a completed canonical plan under
  `docs/plans` and checks that empty placeholder cards are not swiped by the
  like/skip buttons. It also guards against adding network recipe-data markers
  before a data contract exists, keeps the empty-state background sized to the
  card frame, rejects force-casts in the swipe delegate, and rejects forced
  `UIImage(named:)`, `Recipe`, and `superview` optional unwraps in Swift source.

When the required SDK or runtime is unavailable, use static checks and source review first, then verify on a machine that has the matching platform toolchain.

## Configuration and Secrets

- No required secret or credential file was identified in the repository scan. If you add integrations later, keep secrets out of git.

## Security and Privacy Notes

- Review changes touching network requests, sockets, or service endpoints; examples from the scan include RecipeSwipe/Info.plist, RecipeSwipeTests/Info.plist.
- Review changes touching file, media, JSON, XML, CSV, OCR, or data parsing; examples from the scan include RecipeSwipe/API.swift, RecipeSwipe/Info.plist, RecipeSwipe/Recipe.swift, RecipeSwipe/RecipePickerView.swift, and 4 more.

## Maintenance Notes

- This looks like an Apple platform project or sample. Xcode, Swift, CocoaPods, and deployment target versions may need to match the original project era.
- See `SECURITY.md` for vulnerability reporting and safe research guidance.
- See `VISION.md` for project direction and contribution guardrails.
- See `docs/plans/2026-06-08-recipeswipe-baseline.md` for the canonical
  static validation and deferred-card-loading baseline.
- See `docs/plans/2026-06-08-empty-card-swipe-guard.md` for the placeholder
  card swipe guard baseline.
- See `docs/plans/2026-06-08-local-recipe-data-guard.md` for the local data
  boundary baseline.
- See `docs/plans/2026-06-09-empty-state-background-sizing.md` for the
  empty-state background sizing guard.
- See `docs/plans/2026-06-09-swipe-delegate-type-guard.md` for the swipe
  delegate type guard.
- See `docs/plans/2026-06-09-recipe-image-fallback.md` for the sample recipe
  image fallback guard.
- See `docs/plans/2026-06-09-recipe-optional-unwrapping.md` for the recipe
  optional unwrapping guard.
- See `docs/plans/2026-06-09-superview-unwrap-guard.md` for the swipe animation
  superview guard.

## Contributing

Keep changes small and tied to the project that is already present in this repository. For code changes, document the toolchain used, avoid committing generated dependency directories or local configuration, and update this README when setup or verification steps change.
