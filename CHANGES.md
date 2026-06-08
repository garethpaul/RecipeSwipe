# Changes

## 2026-06-08

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
