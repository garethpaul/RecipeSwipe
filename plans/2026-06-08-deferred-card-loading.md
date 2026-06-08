# Deferred Card Loading

## Status

Completed

## Context

`RecipePickerViewController.viewDidLoad` fetches recipes and then immediately
removes the first two entries from `recipes` to create the top and bottom cards.
That works only while the sample fetch remains synchronous. The app should
populate cards from the fetch callback so startup behavior remains safe if the
data source later becomes asynchronous.

## Objectives

- Move initial top and bottom card construction behind the recipe fetch
  callback.
- Keep local sample recipe data and swipe behavior unchanged.
- Avoid removing recipes directly from `viewDidLoad` before data is loaded.
- Extend the static source validator to catch regressions in this startup
  sequence.

## Verification

- `make lint`
- `make verify`
- `git diff --check`
