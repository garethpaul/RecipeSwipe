# Refresh swipe origins after card relayout

Status: Completed

## Scope

Prevent button-triggered swipes from using `MDCSwipeToChoose` geometry captured
before rotation or another card-frame change.

## Implementation

- Track the frame generation used to create the visible cards.
- Rebuild top and bottom card views when idle layout produces a new top frame.
- Preserve deck state and existing swipe lifecycle ownership.
- Add a fail-closed source contract and hostile mutation.
- Update maintained verification counts and change history.

## Validation

- Observe the new swipe-state contract fail before implementation.
- Run Swift core tests and structural contracts.
- Run repository verification through the expected local Apple-tooling boundary.
- Require hosted exact-head checks before merge.
