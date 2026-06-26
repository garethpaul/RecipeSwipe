# Saved Recipe Persistence

## Current Behavior

RecipeSwipe is still a local prototype. `APIClient` returns two hardcoded
recipes backed by the bundled `photo` asset, and a right swipe appends the
runtime `Recipe` object to `RecipePickerViewController.savedRecipes`.

The liked recipes remain process-memory-only today. They are not shown in a
saved-recipes screen, written to disk, restored after relaunch, synchronized,
or sent over the network. A left swipe advances the deck and logs the skip; it
does not delete a previously saved recipe.

## Intended Store

The original 2014 controller marked save and skip handling with a Core Data
TODO. If saved recipes become a maintained feature, implement that intent with
a local Core Data SQLite store behind a small app-owned boundary:

```swift
protocol SavedRecipeStore {
    func save(_ recipe: PersistableRecipe) throws
    func fetchAll() throws -> [PersistedRecipe]
    func remove(recipeID: String) throws
}
```

The protocol names are illustrative, not a committed public API. The important
boundary is that the swipe controller requests a save and does not own Core
Data setup, fetch requests, migrations, or managed objects.

Use `NSPersistentContainer` to own the managed object model, context, and
persistent store. Keep the first implementation local-only. CloudKit, accounts,
remote recipe fetching, and cross-device synchronization require separate data,
privacy, conflict, and credential contracts.

## Identity And Schema

Add a stable recipe identifier before enabling persistence. The normalized
display name is user-facing text and is not a safe unique key: names can repeat
or change independently from recipe identity.

The first model should contain one saved-recipe entity with at least:

- `recipeID`: required string identity with a uniqueness rule
- `name`: the normalized display name captured when saved
- `imageAssetName`: optional bundled asset key or future cache reference
- `savedAt`: required timestamp for deterministic ordering

Saving must be idempotent by recipe ID. Repeating the same completion callback,
restoring state, or seeing the same recipe in a later deck must update or keep
the existing row rather than create duplicate likes.

Do not persist `UIImage`. UIKit image objects are runtime presentation values,
not stable domain records. Persist a small asset/cache reference and resolve it
at display time. If remote images are introduced later, define cache ownership,
eviction, integrity, and missing-file behavior before storing binary data.

## UI And Swipe Boundaries

- Preserve `SwipeDeck` token consumption and `SwipeLifecycle` ownership as the
  authority for exactly-once swipe completion.
- Save only after the deck accepts a right-swipe completion.
- Keep store reads and saved-list presentation outside the active deck so a
  failed fetch cannot reorder or consume cards.
- Treat store failure as a visible, retryable save failure; do not silently
  report a recipe as persisted.
- Make removal an explicit saved-list action. A later left swipe means “skip
  this card now,” not “delete historical saved state.”

## Migration And Testing

Version the managed object model from its first release. Core Data supports
model versioning and migration, but every schema change still needs a fixture or
test proving existing saved data remains readable.

Start repository coverage with an in-memory Core Data store that exercises:

- first save and fetch ordering
- duplicate save idempotence by recipe ID
- explicit removal
- missing optional image references
- save/fetch error propagation through the store boundary
- migration from every previously shipped model version

Disk-backed and relaunch tests should follow before the UI claims persistence.
Until those tests and the saved-recipes presentation exist, keep the current
README statement that likes last only for the running process.

## Implementation Sequence

1. Add stable IDs to the local recipe source and pure recipe model.
2. Add a versioned Core Data model and `SavedRecipeStore` implementation.
3. Add in-memory store tests, then disk/relaunch and migration tests.
4. Inject the store into the picker without changing deck ownership.
5. Add saved-list UI with explicit removal and failure feedback.
6. Update the README only after persistence is executable and verified.

## References

- Repository evidence: initial commit `6166198`, where save and skip methods
  carried the Core Data TODO.
- [Apple Core Data overview](https://developer.apple.com/documentation/coredata/)
- [Apple Core Data stack](https://developer.apple.com/documentation/coredata/core-data-stack)
- [Apple Core Data modeling](https://developer.apple.com/documentation/coredata/modeling-data)
