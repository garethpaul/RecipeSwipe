# RecipeSwipe Setup Guide Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use executing-plans to implement this plan task-by-task.

**Goal:** Replace generated RecipeSwipe setup notes with source-backed workspace, vendored dependency, simulator discovery, timeout, and verification guidance.

**Architecture:** Preserve app behavior, Swift 5/iOS 12 project settings, vendored pods, workspace, tests, runner scripts, and workflow. Add fail-closed static contracts for the maintained setup boundary, correct the stale simulator timeout, and retire only the completed README roadmap item.

**Tech Stack:** Markdown, Ruby static contracts, Swift 5, CocoaPods workspace metadata, Xcode runner shell scripts, GNU Make, GitHub Actions

---

## Status: Completed

### Task 1: Add The Documentation Contract

**Files:**
- Modify: `scripts/check-ios-source.rb`
- Test: `scripts/check-ios-source.rb`

**Step 1: Write the failing test**

Require supported project settings, vendored dependency guidance, workspace use, dynamic simulator discovery, exact timeout defaults, canonical verification, hosted coverage, roadmap history, change history, and plan completion.

**Step 2: Run test to verify it fails**

Run: `ruby --disable-gems scripts/check-ios-source.rb`

Expected: FAIL because the README still contains generated setup notes and a stale 15-second simulator timeout.

### Task 2: Write The Setup Guide

**Files:**
- Modify: `README.md`
- Modify: `VISION.md`
- Modify: `CHANGES.md`

**Step 1: Write minimal documentation**

Document Swift 5/iOS 12, the checked-in workspace and vendored pods, CocoaPods 0.35.0 provenance, safe reconstruction boundaries, dynamic iPhone simulator selection, three 20-second discovery attempts, the 600-second Xcode timeout, canonical Make verification, and hosted macOS coverage.

**Step 2: Run focused contracts**

Run: `ruby --disable-gems scripts/check-ios-source.rb`

Expected: PASS.

### Task 3: Prove Drift Fails Closed

**Files:**
- Test: `scripts/check-ios-source.rb`

**Step 1: Apply hostile mutations**

Mutate setup headings, project versions, workspace guidance, vendored dependency boundary, CocoaPods provenance, simulator selection and timeout defaults, canonical gate, hosted coverage, roadmap, change history, and plan status.

**Step 2: Verify each mutation fails**

Run: `ruby --disable-gems scripts/check-ios-source.rb` after each mutation.

Expected: every mutation is rejected.

### Task 4: Run The Full Gate

**Files:**
- Verify: `Makefile`

**Step 1: Run repository and external gates**

Run: `/usr/bin/make check`

Run: `cd "$(mktemp -d)" && /usr/bin/make -f /absolute/path/to/Makefile check`

Expected: portable source, Swift package, runner, mutation, workflow, asset, and Make authority gates pass; unavailable Xcode phases report their documented platform boundary.

### Task 5: Commit And Ship

**Files:**
- Modify: `CHANGES.md`
- Modify: `docs/plans/2026-06-26-recipeswipe-setup-guide.md`

**Step 1: Record exact validation**

Add mutation, local gate, hosted Xcode, review, and blocker evidence.

**Step 2: Commit**

```bash
git add README.md VISION.md CHANGES.md scripts/check-ios-source.rb docs/plans/2026-06-26-recipeswipe-setup-guide.md
git commit -m "docs: correct RecipeSwipe setup guidance"
```

## Results

- Replaced generated setup inventory with source-backed workspace, vendored
  dependency, simulator, timeout, portable, and hosted verification guidance.
- Corrected stale README claims from a 15-second simulator timeout and four
  Swift tests to three 20-second discovery attempts and seven Swift tests; also
  recorded the maintained 23 state and 13 workflow mutations.
- Rejected 18 hostile documentation mutations, including plan completion and
  UTF-8/ASCII-locale portability coverage.
- Passed `structural`, `core-test`, and `root-test` from the checkout and an
  external working directory in a clean Swift/Ruby container. Full `make check`
  reached the expected native boundary at missing Linux `xcrun`; hosted macOS
  remains responsible for XCTest and the generic simulator build.
