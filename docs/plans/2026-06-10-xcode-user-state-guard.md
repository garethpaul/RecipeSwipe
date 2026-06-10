# Xcode User State Guard

## Status: Completed

## Context

`RecipeSwipe` already ignored common Xcode user-state files, but the static
source validator did not fail if those machine-local files were accidentally
tracked later. Per-user project state can include local workspace choices,
debugger state, and other machine-specific details that should not be part of
the sample app source.

## Objectives

- Reject tracked `xcuserdata` entries.
- Reject tracked `.xcuserstate`, `.pbxuser`, `.mode*v3`, `.perspectivev3`,
  `.xccheckout`, `.moved-aside`, `.hmap`, and `.ipa` files.
- Preserve default Xcode template exception filenames already represented in
  `.gitignore`.
- Keep the guard inside the existing dependency-free Ruby static checker.

## Work Completed

- Extended `scripts/check-ios-source.rb` to inspect tracked files with
  `git ls-files`.
- Added a static failure message for tracked Xcode user-state artifacts.
- Updated README, VISION, and CHANGES maintenance notes.

## Verification

- `ruby -c scripts/check-ios-source.rb`
- `ruby scripts/check-ios-source.rb`
- `make check`
- `git diff --check`
