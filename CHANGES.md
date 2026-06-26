# Changes

## 2026-06-26 02:55 PDT - P2 - Define saved-recipe persistence boundary

### Summary

Documented the intended Core Data path for saved recipes while preserving the
truth that the current prototype keeps likes only in process memory.

### Work completed

- Recovered the original 2014 Core Data TODO from source history.
- Defined a local SQLite-backed Core Data store behind an app-owned protocol.
- Required stable recipe identity, idempotent saves, metadata-only image
  references, explicit removal, and model versioning.
- Separated saved-list storage from deck consumption and gesture ownership.
- Defined in-memory, disk/relaunch, failure, and migration tests required before
  runtime persistence can be claimed.
- Added a portable documentation contract and reconciled the completed roadmap
  item.

### Threads

- Started: saved-recipe persistence architecture documentation.
- Continued: local-data boundary — retained hardcoded recipes and no network or
  CloudKit behavior.
- Stopped: none.

### Files changed

- `docs/persistence.md` — records current behavior and the future Core Data
  architecture.
- `scripts/check-ios-source.rb` — fails closed if persistence guarantees drift.
- `README.md`, `VISION.md`, and the completed plan — expose and preserve the
  decision.

### Validation

- Red-first containerized source check — failed on all missing persistence,
  roadmap, history, and plan contracts.
- Ruby 3.3 source validation, 11 asset tests, 23 swipe mutations, 13 workflow
  mutations, Xcode-runner contracts, 7 Swift tests, and 56 Make authority cases
  — passed from checkout and `/tmp` in a Swift 6.0/Ruby container.
- Full `make check` reached the expected missing-`xcrun` Linux boundary; hosted
  macOS remains responsible for XCTest and simulator build evidence.
- Ruby and shell syntax checks plus `git diff --check` — passed.
- Hosted exact-head checks, review, and merge remain the next action.

### Bugs / findings

- P2 documentation: the roadmap named persistence but did not define identity,
  image storage, duplicate-save, failure, migration, or UI ownership semantics.

### Blockers

- No runtime blocker because this cycle does not claim or implement persistence.
- Local Apple tooling is unavailable; the portable gates passed in containers.

### Next action

- Run portable and hosted exact-head validation, then review and merge the
  focused documentation PR.

## 2026-06-26 01:59 - P2 - Correct setup and simulator guidance

### Summary

Replaced generated setup notes with a source-backed RecipeSwipe setup and
simulator guide. Corrected the documented simulator discovery timeout from 15
seconds to the maintained runner's three 20-second attempts.

### Work completed

- Documented the Swift 5/iOS 12 project baseline, shared workspace and scheme,
  checked-in pod boundary, CocoaPods 0.35.0 provenance, and code-signing-free
  simulator path.
- Documented dynamic first-available-iPhone selection, UDID targeting, exact
  discovery and Xcode timeout defaults, canonical Make verification, and hosted
  `macos-15` coverage.
- Warned against routine `pod update` or unreviewed dependency regeneration.
- Retired only the completed setup roadmap item; persistence design remains a
  separate next priority.

### Threads

- None. The cycle was completed directly after excluding repositories with
  active public pull requests or pending default-branch checks.

### Files changed

- `README.md` — added project, dependency, simulator, and verification setup guidance.
- `VISION.md` — recorded the maintained setup boundary and removed the completed item.
- `scripts/check-ios-source.rb` — added fail-closed setup-guide contracts.
- `docs/plans/2026-06-26-recipeswipe-setup-guide.md` — recorded the implementation plan.

### Validation

- Ruby source contract — expected red result observed in a clean Ruby 3.3 container.
- Eighteen hostile setup-guide mutations — all rejected, covering project
  versions, workspace, vendored dependencies, simulator selection, timeout and
  test counts, canonical/hosted gates, roadmap, history, and plan status.
- `/usr/bin/make structural core-test root-test` — passed from the checkout and
  an external working directory in a clean Swift 6.2.3/Ruby 3.2 container: 7
  Swift tests, 11 asset tests, 23 swipe-state mutations, 13 workflow mutations,
  Xcode-runner contracts, and 56 Make authority cases.
- `/usr/bin/make check` — portable phases passed, then the Linux container
  stopped at the intentional native boundary because `xcrun` is unavailable.
- Ruby ASCII-locale probe — passed after documentation reads were made
  explicitly UTF-8.

### Bugs / findings

- README documented a 15-second simulator discovery timeout, but
  `scripts/xcode-test.sh` defaults to 20 seconds and retries three times.
- README documented four pure Swift tests and 25 combined state/workflow
  mutations; the maintained gate currently runs seven Swift tests, 23
  swipe-state mutations, and 13 workflow mutations.
- Routine `pod install`/`pod update` guidance was unsafe for the checked-in
  CocoaPods 0.35.0-era workspace and vendored dependency graph.

### Blockers

- This Linux host has no Ruby, Swift, Xcode, simulator, or CocoaPods runtime;
  portable validation must use clean containers and hosted macOS remains
  required for native XCTest/build evidence.

### Next action

- Document the intended local persistence path for liked recipes without
  introducing storage or network behavior in the same change.

## 2026-06-21

- Hardened all seven pre-existing Make gates against caller-controlled root and
  shell authority, preloaded Makefiles, ambiguous Makefile lists, and
  shell-sensitive checkout paths without changing app or swipe behavior.
- Rejected later target-replacing Makefiles and non-executing/error-ignoring
  Make modes, and documented the trusted `PATH` and GNU Make preload boundary.

## 2026-06-19

- Modernized the archived app to Swift 5 and iOS 12 so its app and XCTest targets build with current Xcode.
- Replaced callback-driven array mutation with a generation-token deck that rejects duplicate and stale swipe completions.
- Added explicit translation/velocity direction validation, guarded nullable pan callbacks, and main-thread UI ownership.
- Added bounded recipe-name sanitization, Dynamic Type, multiline labels, and explicit card/button accessibility.
- Added location-independent SwiftPM, XCTest, mutation, asset, workflow, and dual-architecture simulator gates.

## 2026-06-13

- Restricted swipe completion to explicit Left and Right directions so
  `MDCSwipeDirection.None` cannot skip a recipe or advance the card stack.

## 2026-06-12

- Guarded the swipe pan callback before reading its implicitly unwrapped state
  and added structural validation for the optional binding.
- Added dependency-free asset catalog path, size, extension, and PNG/JPEG
  signature validation.
- Added Minitest coverage and wired asset integrity into structural and full
  Make gates.

## 2026-06-10

- Added pinned, credential-free, read-only macOS structural validation without
  installing archived pods or invoking an unsupported modern Xcode build.
- Added dependency-free workflow contract mutation tests for trigger,
  credential, action, permission, runner, timeout, dispatch, and legacy-build
  drift.
- Made tracked-file inspection fail closed when Git cannot inspect the checkout.
- Added static validation to reject tracked Xcode user-state files.
- Disabled like/nope controls when no recipe card is active so the empty state
  no longer exposes ineffective actions.

## 2026-06-09

- Added accessibility labels and static validation for the image-only like/nope
  controls.
- Moved like/nope controls above the empty-state background layer and added
  static validation to prevent those buttons from being inserted behind artwork.
- Guarded swipe animation superview access and added static validation to keep
  Swift source free of `superview!` force unwraps.
- Replaced forced recipe optional unwraps with guarded bindings and added
  static validation to keep recipe UI paths crash-safe.
- Replaced forced sample recipe image unwraps with a checked fallback and added
  static validation to keep Swift image loads guarded.
- Guarded the swipe delegate against non-recipe views and added static
  validation so delegate callbacks cannot force-cast placeholder views.
- Fixed the empty-state background image height to follow the bottom card frame
  height and added static validation for that layout guard.

## 2026-06-08

- Added a static local-data guard so Swift source cannot introduce network
  recipe fetching before a data contract exists.
- Added a guarded top-card swipe helper so like/skip buttons ignore empty
  placeholder cards after recipes run out.
- Added a static iOS source validation gate for UIKit imports, asset catalog
  references, CocoaPods lockfile consistency, and bridging-header project paths.
- Added `make check` as the shared repository verification alias.
- Fixed Swift files that used `UIImage` without importing UIKit.
- Replaced a stale `UIImage(named: "photo.jpg")` lookup with the asset catalog
  name `photo`.
- Replaced the machine-local bridging header setting with the repo-relative
  `RecipeSwipe/BridgeHeader.h` path.
- Deferred initial card construction until the recipe fetch callback populates
  local sample data, with validator coverage for that startup sequence.
- Added canonical `docs/plans` coverage and made the static source validator
  require completed plans.
