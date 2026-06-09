# Changes

## 2026-06-09

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
