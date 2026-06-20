# Asset Catalog File Integrity

## Status: Completed

## Context

The structural checker confirms that filenames declared by asset-catalog
`Contents.json` files exist. It does not currently prove that a filename stays
inside its imageset, that the file is non-empty and reasonably sized, or that a
`.png` or `.jpg` entry contains the corresponding image signature.

## Priority

The archived app depends on checked-in image assets and cannot rely on a modern
Xcode build to diagnose every corrupt catalog entry. A dependency-free file
contract gives Linux and hosted validation a truthful integrity boundary.

## Requirements

- R1. Asset filenames must be plain basenames without absolute paths,
  separators, or dot-segment traversal.
- R2. Referenced files must exist, be non-empty, and be no larger than 5 MiB.
- R3. `.png` files must carry the PNG signature.
- R4. `.jpg` and `.jpeg` files must carry a JPEG start-of-image signature.
- R5. Other image extensions must fail closed until explicitly reviewed.
- R6. Unit tests must cover valid PNG/JPEG files and every rejection path.
- R7. `make check` must run the asset-contract tests alongside workflow tests
  and the existing source checker.

## Scope Boundaries

- Do not rewrite, recompress, or otherwise change image assets.
- Do not claim that signature checks decode or fully validate image content.
- Do not install CocoaPods or require Xcode for this focused change.

## Verification Plan

- `ruby -w -c scripts/asset-contract.rb`
- `ruby -w -c scripts/test-asset-contract.rb`
- `ruby scripts/test-asset-contract.rb`
- `ruby scripts/check-ios-source.rb`
- `make structural`
- `make check`
- focused hostile asset-contract mutations
- `git diff --check`

## Work Completed

- Added a dependency-free `AssetContract` module for filename containment,
  existence, size, extension, and PNG/JPEG signature checks.
- Replaced the source checker's existence-only asset validation with the shared
  contract while preserving `Contents.json` context in failures.
- Added Minitest coverage for valid PNG/JPEG files and every rejection path.
- Wired asset-contract tests into `contract-test`, `structural`, `test`,
  `verify`, and `make check`.
- Updated maintenance, security, roadmap, and change documentation.

## Verification Completed

- `ruby -w -c scripts/asset-contract.rb` passed.
- `ruby -w -c scripts/test-asset-contract.rb` passed.
- `ruby scripts/test-asset-contract.rb` passed 11 tests and 33 assertions.
- `ruby scripts/check-ios-source.rb`, `make structural`, and `make check`
  passed; unavailable Xcode build and XCTest steps were reported without being
  misrepresented as executed.
- All 12 focused hostile mutations were rejected from a passing baseline,
  covering the size limit, canonical signatures, path separators, empty and
  oversized files, unsupported extensions, source and Make wiring, completed
  plan status, a corrupted real PNG, and a traversal-style catalog filename.
- `git diff --check` passed.
