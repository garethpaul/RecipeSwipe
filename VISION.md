## RecipeSwipe Vision

RecipeSwipe is a legacy iOS prototype for swiping through recipe cards, saving
liked recipes, and skipping unwanted ones.

The repository is useful as a small Swift app example using card-style swipe
interactions, local hardcoded recipe data, and a simple saved-recipes array.

The goal is to preserve the prototype while clarifying what must change before
it becomes a real recipe app.

The current focus is:

Priority:

- Preserve the swipe-card interaction and like/skip flow
- Keep sample recipe data clearly local and fake
- Treat Swift, Xcode, and dependency versions as legacy
- Avoid adding network recipe fetching before data boundaries are documented

Next priorities:

- Add README setup notes for Xcode, CocoaPods, and simulator expectations
- Fix startup behavior so recipe data is loaded before card removal
- Document the intended persistence path for saved recipes
- Modernize Swift syntax in a dedicated pass

Contribution rules:

- One PR = one focused UI, data, persistence, dependency, or documentation change.
- Do not commit real user preference data.
- Include simulator notes for interaction changes.
- Keep data-source changes separate from swipe behavior.

## Security And Responsible Use

Recipe preference data can still reveal user habits. The prototype should keep
preferences local unless an explicit, documented backend is introduced.

## What We Will Not Merge (For Now)

- Silent upload of liked or skipped recipes
- Real user data in fixtures
- Broad Swift rewrites without behavior checks
- Network API calls before the data contract is documented

This list is a roadmap guardrail, not a permanent rule.
Strong user demand and strong technical rationale can change it.
