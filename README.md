# RecipeSwipe

<!-- README-OVERVIEW-IMAGE -->
![Project overview](docs/readme-overview.svg)

## Device Preview

<!-- DEVICE-PREVIEW-IMAGE -->
![Device preview](docs/device-preview.svg)

## Overview

`garethpaul/RecipeSwipe` is a preserved iOS prototype for swiping through local
recipe cards, liking recipes, and skipping unwanted cards. The maintained
baseline focuses on deterministic deck state, gesture safety, accessibility,
and reproducible simulator verification rather than production persistence or
network recipe data.

## Repository Contents

- `RecipeSwipe/` - application source, local sample recipes, card/deck logic,
  storyboard, and assets
- `RecipeSwipeTests/` - native XCTest coverage for maintained app behavior
- `Tests/RecipeSwipeCoreTests/` - pure Swift package tests for deck state
- `RecipeSwipe.xcworkspace` - CocoaPods-integrated Xcode entry point
- `RecipeSwipe.xcodeproj` - Swift 5/iOS 12 project settings
- `Pods/`, `Podfile`, and `Podfile.lock` - checked-in legacy swipe dependency
- `Package.swift` - dependency-free Swift package surface for core deck tests
- `scripts/` and `Makefile` - canonical source, asset, mutation, simulator,
  build, workflow, and Make authority gates
- `docs/plans/` - completed maintenance decisions and validation evidence

## Getting Started

### Supported Project Baseline

- Git
- macOS with Xcode and at least one available iPhone simulator
- Swift 5 with an iOS 12 deployment target, as pinned across the project and
  target build configurations
- The checked-in `RecipeSwipe.xcworkspace`, vendored `Pods/`, and lockfile with
  CocoaPods 0.35.0 provenance
- Ruby for the source, workflow, mutation, timeout, and runner contracts

### Setup

```bash
git clone https://github.com/garethpaul/RecipeSwipe.git
cd RecipeSwipe
open RecipeSwipe.xcworkspace
```

Choose the shared `RecipeSwipe` scheme. The project and test runners disable
code signing for simulator verification, so local signing changes are not part
of routine validation.

### Vendored Dependency Boundary

The repository checks in its workspace and legacy `MDCSwipeToChoose` pod.
Routine builds and hosted verification do not install or resolve CocoaPods.
Do not run pod update as routine setup. If dependency reconstruction becomes
necessary, use a disposable worktree with a historically compatible CocoaPods
version, review every generated project and lockfile change, and keep that work
separate from app behavior changes.

## Running or Using the Project

- Open `RecipeSwipe.xcworkspace`, choose the shared `RecipeSwipe` scheme, and
  run on an available iPhone simulator. The current sample data is local and
  hardcoded; liked recipes remain only in the process-memory array.
- See `docs/persistence.md` for the intended local Core Data path, stable recipe
  identity, metadata-only image policy, and tests required before the app can
  claim that likes survive relaunch.

## Testing and Verification

### Dynamic Simulator Selection

`scripts/xcode-test.sh` asks `simctl` for available devices and selects the
first available iPhone simulator by UDID rather than depending on a retired
model name. Discovery gets three 20-second discovery attempts. The XCTest and
generic simulator build phases use a 600-second xcodebuild timeout. Override
the defaults with `RECIPESWIPE_SIMCTL_TIMEOUT` and
`RECIPESWIPE_XCODEBUILD_TIMEOUT` only when diagnosing a known slow host.

### Canonical Verification

Run the location-independent maintained gate:

```sh
/usr/bin/make check
```

- The gate runs 7 pure Swift deck and gesture tests, the native XCTest suite on
  an available iPhone simulator, 11 asset-contract tests, 23 hostile
  swipe-state mutations, 13 hostile workflow mutations, Xcode-runner contracts,
  and a generic arm64/x86_64 simulator build.
- The swipe controller binds approval and completion to the active card identity,
  uses generation tokens for exactly-once deck consumption, validates finite
  aligned translation/velocity thresholds, and rejects stale pan callbacks.
- Recipe names are control-character sanitized and bounded; card names use
  Dynamic Type, two-line resizing, and explicit VoiceOver action descriptions.

### Hosted Verification

GitHub Actions runs the same gate on `macos-15` for pushes, pull requests, and
manual dispatches. Hosted verification uses credential-free checkout,
read-only permissions, a commit-pinned action, bounded simulator/Xcode runners,
the native XCTest suite, and the generic simulator build without reinstalling
the archived CocoaPods dependency.

On a non-macOS host, run the portable `structural`, `core-test`, and `root-test`
targets in a Swift/Ruby environment. The complete `check` target intentionally
requires `xcrun`, an available iPhone simulator, and `xcodebuild`; a missing
Apple toolchain is a blocked native gate, not a passing skip.

## Configuration and Secrets

- No required secret or credential file was identified in the repository scan. If you add integrations later, keep secrets out of git.

## Security and Privacy Notes

- Review changes touching network requests, sockets, or service endpoints; examples from the scan include RecipeSwipe/Info.plist, RecipeSwipeTests/Info.plist.
- Review changes touching file, media, JSON, XML, CSV, OCR, or data parsing; examples from the scan include RecipeSwipe/API.swift, RecipeSwipe/Info.plist, RecipeSwipe/Recipe.swift, RecipeSwipe/RecipePickerView.swift, and 4 more.

## Maintenance Notes

- Within the checked-in Makefile boundary, Make gates reject ordinary caller
  root and shell assignments, preloaded Makefiles, later single-colon recipe
  replacement, non-executing/error-ignoring modes, and unsafe shell-sensitive
  checkout paths before running structural, SwiftPM, XCTest, or Xcode
  validation. Arbitrary caller Make programs remain outside that boundary:
  GNU Make `override` directives, caller-added double-colon recipes, and
  startup parse-time code can execute with Make-level authority. Trusted
  automation must also provide the intended Ruby, Swift, and Xcode toolchain
  on `PATH` and avoid caller-supplied Makefiles. Repository aliases pin their
  shell target-specifically and embed the reviewed checkout root before later
  non-override target-specific variables can alter recipe execution.

- This archived sample is maintained as Swift 5 with an iOS 12 deployment target and its vendored CocoaPods dependency.
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
- See `docs/plans/2026-06-09-swipe-button-layering.md` for the swipe button
  layering guard.
- See `docs/plans/2026-06-09-swipe-button-accessibility-labels.md` for the
  image-only swipe button accessibility label guard.
- See `docs/plans/2026-06-10-xcode-user-state-guard.md` for the tracked Xcode
  user-state file guard.
- See `docs/plans/2026-06-10-empty-state-button-disable.md` for swipe control
  enabled-state synchronization when recipes run out.
- See `docs/plans/2026-06-10-hosted-structural-validation.md` for the pinned
  macOS structural gate and legacy build boundary.
- See `docs/plans/2026-06-12-swipe-pan-state-guard.md` for the nullable pan
  callback guard.
- See `docs/plans/2026-06-13-all-pan-state-guards.md` for repository-wide pan
  callback enforcement and hostile mutation coverage.
- See `docs/plans/2026-06-16-recipe-name-label-autoresizing.md` for the recipe
  name label resizing contract and hostile mutation coverage.
- See `docs/persistence.md` for the intended local Core Data path for saved
  recipes. It documents future architecture only; current likes remain
  process-memory-only.

## Contributing

Keep changes small and tied to the project that is already present in this repository. For code changes, document the toolchain used, avoid committing generated dependency directories or local configuration, and update this README when setup or verification steps change.
