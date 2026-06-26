# Card relayout swipe-origin design

Status: Completed

## Problem

The vendored `MDCSwipeToChoose` implementation records a card's original center
when the card is created or a user gesture begins. RecipeSwipe later updates card
frames during layout, but a button-triggered `mdc_swipe` does not refresh that
stored center. After rotation or another horizontal size change, the dependency
can classify a requested left swipe as right, reject it through the controller's
intent guard, and leave the card displaced with swipe controls disabled.

## Decision

Treat the visible card frame as a layout generation. While no gesture or
transition owns the deck, replace the two visible card views whenever the top
frame changes. Recreating the views refreshes the dependency's private original
center without importing its internal state, modifying vendored code, or adding
duplicate gesture recognizers.

## Constraints

- Never rebuild cards while swipe ownership is active.
- Preserve the deck, generation token, recipe order, and saved recipes.
- Recreate both visible cards because the bottom card may later become top.
- Keep the existing identity and token checks for all delegate callbacks.

## Evidence

The swipe-state contract requires the idle relayout refresh and includes a
hostile mutation that removes it. Portable structural validation covers the
guard; hosted iOS validation remains responsible for UIKit integration.
