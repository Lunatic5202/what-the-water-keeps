# Implementation Status

**Last Updated:** 2026-10-26  
**Prototype:** Wake → The Still Pond → The Gilded Garden

## Implemented in code

### The Wake
- Movement, jump, dash, lantern swing, health and healing
- Slumber Hollow (Sloth) with Drowse, three enemy types, platforming, benches and The Dreamer; Snail Grips wall climb (never run in Godot)
- Lantern Swing extras: heavy, Lantern Flash (stun), guard, Warm Light (never run in Godot)
- Open Hand fighting style (full kit), Glow, Tab style swap, five-petal Glow ring (never run in Godot)
- Wake rooms with room-locked camera; hub killbox and reachable hub platforms (never run in Godot)
- Story pass: hub arrival cutscene, Nim lines in Greed, post-Greed and post-Sloth hub dialogue, a silent growing pond figure (no Reflection text), Nim post hints (never run in Godot)
- Title, pause, settings and controls menus; lantern HUD meter; Reduce Shake, Gentle Mode and Fullscreen options (never run in Godot)
- Four E-to-read signs; dialogue closes when Lumi walks away
- Little Jelly tutorial enemy
- Old Moss tutorial boss with readable attack wind-ups, head lunge, rolling shell, spore fan and a faster phase-two aimed burst
- Post-defeat Wind Ribbon reveal
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
- The Collector boss: three phases (Coin Rain and belly slam, Feast growth with a shrinking arena, Hunger purse grab), offering bowls that hurt and shrink him, and the bible's intro, mid-fight and defeat lines
- Greed clear: defeating him sets the Open Hand and Gold Key flags, emits `region_cleared`, and the hub counts the key
- Featherweight Charm pickup sets the player's double-jump ability
- Return-to-hub signal that does not falsely count Greed as cleared

### Shared systems
- Checkpoint-aware player death respawn
- Reuse of the same Lumi instance across Wake, hub and Greed
- Hit-stop and camera shake through a dedicated feedback node that only releases pauses it owns

## Still incomplete
- Open Hand (Offering Style) as a real fighting style. It is only a flag today
- Unlocking further regions from completed boss clears
- Other six regions, fighting styles, Memory Petals, save/load, map/loadout/Memory Tree/keepsake screens, key remapping and endings
- Final art, animation, music and sound

## Verification status

The repository has been updated through source changes, but the game has **not** been launched in Godot as part of this work. Playtest:
1. Wake → Hub transition with T
2. Hub → Greed transition from the Greed door
3. Greed → Hub return without falsely unlocking Greed
4. Dash-gap reachability and checkpoint respawn after damage/falling
5. Featherweight double jump and hit-stop recovery
6. The Collector fight start to finish: intro, coin rain, slam, feast (mountain disappears, he grows), purse grab with and without gold, bowls, defeat, return to hub with the key counted
7. Dying mid-fight resets him and removes the lock wall

## Engine version

`project.godot` advertises Godot 4.7 in `config/features`; use Godot 4.7 or newer unless the feature tag is deliberately changed and the project is verified on an older version.
