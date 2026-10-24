# Implementation Status

**Last Updated:** 2026-10-24  
**Prototype:** Wake → The Still Pond → The Gilded Garden

## Implemented in code

### The Wake
- Movement, jump, dash, lantern swing, health and healing
- Four E-to-read signs; dialogue closes when Lumi walks away
- Little Jelly tutorial enemy
- Old Moss tutorial boss and post-defeat Wind Ribbon reveal
- Wind Ribbon unlocks dash and establishes the Wake checkpoint
- Dash-training gap after the Ribbon, before the first door
- Visible level boundaries, camera limits and pit recovery

### The Still Pond
- Multi-tier hub with seven region doors
- Bench, Altar of Hands, Memory Tree, Nim's Lantern Post and Mirror Gate placeholder
- Marl and Orrin dialogue
- Player handoff from Wake and door signal for Greed

### The Gilded Garden (Greed)
- Coins, carried-gold weight penalty, shrines and three lore tablets
- Collector encounter placeholder (boss fight is not implemented)
- Featherweight Charm pickup sets the player's double-jump ability
- Return-to-hub signal that does not falsely count Greed as cleared

### Shared systems
- Checkpoint-aware player death respawn
- Reuse of the same Lumi instance across Wake, hub and Greed
- Hit-stop and camera shake through a dedicated feedback node that only releases pauses it owns

## Still incomplete
- The Collector boss fight, actual Greed clear condition, and Greed rewards beyond Featherweight
- Unlocking further regions from completed boss clears
- Other six regions, fighting styles, Memory Petals, save/load, menus and endings
- Final art, animation, music and sound

## Verification status

The repository has been updated through source changes, but the game has **not** been launched in Godot as part of this work. Playtest:
1. Wake → Hub transition with T
2. Hub → Greed transition from the Greed door
3. Greed → Hub return without falsely unlocking Greed
4. Dash-gap reachability and checkpoint respawn after damage/falling
5. Featherweight double jump and hit-stop recovery

## Engine version

`project.godot` advertises Godot 4.7 in `config/features`; use Godot 4.7 or newer unless the feature tag is deliberately changed and the project is verified on an older version.
