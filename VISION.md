## RecipeSwipe Vision

RecipeSwipe is a legacy iOS prototype for swiping through recipe cards, saving
liked recipes, and skipping unwanted ones.

The repository is useful as a small Swift app example using card-style swipe
interactions, local hardcoded recipe data, and a simple saved-recipes array.

The goal is to preserve the prototype while clarifying what must change before
it becomes a real recipe app.

Current baseline: `make check` runs static iOS source validation, optional
Xcode build/test commands when available, local recipe-data boundary checks, and
canonical `docs/plans` coverage.

The current focus is:

Priority:

- Preserve the swipe-card interaction and like/skip flow
- Keep sample recipe data clearly local and fake
- Treat Swift, Xcode, and dependency versions as legacy
- Maintain `make check` for static source validation and optional Xcode checks
- Avoid adding network recipe fetching before data boundaries are documented
- Keep network recipe-data markers out of Swift source until a contract exists
- Keep empty placeholder card behavior safe when recipe data runs out
- Keep empty-state background artwork aligned to the card frame
- Keep like/nope controls above the empty-state background artwork
- Keep image-only like/nope controls labelled for accessibility
- Disable like/nope controls when no recipe card is active
- Keep swipe delegate callbacks guarded before advancing the card stack
- Keep sample recipe image loading guarded against missing assets
- Keep optional recipe values guarded before saving, skipping, or displaying
- Keep swipe animation parent-view access guarded before reading `superview`
- Keep Xcode user-state files out of tracked source
- Run the dependency-free structural gate on a fixed macOS runner with
  read-only permissions and pinned actions
- Keep hosted validation separate from unsupported modern Xcode builds and
  archived CocoaPods installation
- Keep completed maintenance plans under `docs/plans`

Next priorities:

- Add README setup notes for Xcode, CocoaPods, and simulator expectations
- Document the intended persistence path for saved recipes
- Modernize Swift syntax in a dedicated pass

Contribution rules:

- One PR = one focused UI, data, persistence, dependency, or documentation change.
- Do not commit real user preference data.
- Include simulator notes for interaction changes.
- Keep data-source changes separate from swipe behavior.

## Security And Responsible Use

Canonical security policy and reporting:

- [`SECURITY.md`](SECURITY.md)

Recipe preference data can still reveal user habits. The prototype should keep
preferences local unless an explicit, documented backend is introduced.

## What We Will Not Merge (For Now)

- Silent upload of liked or skipped recipes
- Real user data in fixtures
- Broad Swift rewrites without behavior checks
- Network API calls before the data contract is documented

This list is a roadmap guardrail, not a permanent rule.
Strong user demand and strong technical rationale can change it.
