# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A World of Warcraft addon for 12.0.1 (Midnight) that displays an image of Ron and visual effects when the player dies. The main frame parents itself to the `StaticPopup1` death dialog ("Release Spirit") so it moves/hides with that popup.

## Architecture

Single-file addon (`RonsFault.lua`), no build step. The TOC file (`RonsFault.toc`) is the WoW addon manifest.

**Two independent visual layers on death:**
1. **Main frame** (`RonsFaultFrame`) — ron-warrior image + "Ron's Fault" label, parented to the death dialog. A random effect from the `EFFECTS` table is applied to the label each death (currently: rainbow gradient).
2. **Scroller** (`RonsFaultScrollFrame`) — per-character "DON'T RELEASE" text scrolling across the screen in a sine wave. Always shows on death, not part of the random effect pool.

**Adding new random effects:** Add a `{ start = fn, stop = fn }` entry to the `EFFECTS` table. The `start` function sets up the animation (typically via `frame:SetScript("OnUpdate", ...)`), and `stop` tears it down. Effects apply to the `label` FontString on the main frame.

## WoW API details

- The death dialog is `StaticPopupDialogs["DEATH"]`, rendered in `StaticPopup1`, positioned at `TOP, UIParent, TOP, 0, -135`.
- `PLAYER_DEAD` fires the show (with 0.1s delay for the popup to exist); `PLAYER_ALIVE`/`PLAYER_UNGHOST` fires the hide.
- Saved variables: `RonsFaultDB` (just an `enabled` bool).

## Textures

WoW cannot load `.png` files. Textures must be `.tga` (32-bit RGBA) or `.blp`. The Lua references paths without extension (`Interface\AddOns\RonsFault\ron-warrior`) so WoW resolves the format automatically. Convert with: `magick input.png output.tga`

## Testing in-game

- `/rf test` — shows the death dialog + addon without dying
- `/rf hide` — hides everything
- `/rf toggle` — enable/disable
- `/reload` — reload UI after code changes
