# Implementation Checklist

## From Design Docs

### Combat (what-the-water-keeps-combat-and-movesets.md)
- [x] 5 hearts health (user override of doc's 100 HP)
- [x] 3 heal charges
- [x] Lantern Swing 8/8/12 damage combo
- [x] Dash gated behind Wind Ribbon pickup
- [ ] Glow meter (0-100, +5 per hit, +15 perfect guard)
- [ ] Heavy attack (K key, 22 damage)
- [ ] Guard/perfect guard (I key, 0.25s window)
- [ ] Gadgets properly gated behind artifacts

### Art & UI (what-the-water-keeps-art-sound-ui.md)
- [x] Hub palette: lavender, peach, mint, deep indigo (#C9B8F0, #FFD9C0, #CFF1E0, #4A3A7A)
- [x] Wake palette: meadow green, cream, sky (#BFE3B4, #FFF6DC, #CFE8F7)
- [ ] Lumi: 1.5 heads tall, lavender cloak, paper lantern, hop walk
- [x] Lantern flame shrinks with health (HUD meter; untested in Godot)
- [ ] Pastel storybook look, no pure black
- [ ] Glowing particles everywhere
- [x] HUD: lantern icon health, 3 oil drops, 5-petal Glow ring (untested in Godot)
- [ ] Minimal text, crayon signs only

### Tutorial (Wake) Structure
- [ ] Full 8-room layout per spec; current prototype compresses the tutorial path, Old Moss arena, Wind Ribbon and dash gap
- [x] Old Moss boss (120 HP, 8-10 damage)
- [ ] Missing: Puddle Sprite (HP 15, dmg 5), Dust Bunny (HP 12, dmg 5)
- [x] Little Jelly (HP 10, dmg 1 - tutorial scaled)

### Hub Requirements
- [x] Multi-tier platformer layout
- [x] Seven doors spread across elevations
- [x] Bench of Rest, Altar of Hands, Memory Tree, Mirror Gate
- [ ] NPCs with full dialogue (currently stubbed)
- [ ] Hub music "Still Water" loses one note per region

### Current Violations
1. ~~Hub never loads~~ - FIXED: main.gd now removes player before hub._ready()
2. **HUD** - lantern meter and Glow ring added (untested)
3. **Missing Glow system** entirely
4. **No Heavy attack** or Guard
5. **Dialogue too brief** - art doc says "minimal text" but narrative needs room
6. **No particles** - spec requires glowing particles everywhere
7. **Color drift** - some colors don't match hex specs exactly

### Next Priority
1. ~~Fix hub instantiation~~ - DONE
2. ~~Add missing Wake enemies~~ - Puddle Sprite and Dust Bunny created
3. Implement Glow meter and Heavy/Guard moves
4. Proper HUD with lantern icon
5. Particle systems

### Just Completed (2026-10-24)
- Fixed Wake→Hub transition (player ownership handoff)
- Created Puddle Sprite (15 HP, 5 dmg, hop/puddle behavior)
- Created Dust Bunny (12 HP, 5 dmg, flee behavior, puff visual)


## Progression fixes in progress (2026-10-24)
- [x] Restore the post-Ribbon dash gap before the first door
- [x] Replace frame-polled T transition with per-frame input handling
- [x] Wire Wake → Hub → Greed → Hub handoffs
- [x] Keep region return separate from region-clear progression
- [x] Make player death use the current checkpoint
- [x] Connect Featherweight pickup to actual double-jump ability
- [x] Integrate hit-stop/camera shake without a pause deadlock
- [ ] Run the full loop in Godot and fix any runtime errors


## The Collector (2026-10-24, not yet run in Godot)
- [x] Coin Rain and belly slam (phase 1)
- [x] Feast: swallows the mountain, grows faster with carried gold, arena shrinks (phase 2)
- [x] Hunger: purse grab steals gold and heals him; empty hands whiff and stagger him (phase 3)
- [x] Offering bowls hurt and shrink him
- [x] Defeat: shrinks to a crying bear with one coin, fades; Open Hand and Gold Key flags; Greed clear unlocks the hub key
- [ ] Playtest and tune health (360 vs bible 700), timings, growth and squeeze
- [ ] Open Hand as a real fighting style (Offering Style)
- [ ] Boss music and sound

## Difficulty, saves and challenge (headless-tested logic, not played)
- [x] Gentle / Normal / Hard on New Game
- [x] Escalating debuff costs (Drowse, Weight)
- [x] Bench-only save, Continue, Return to title
- [x] Secret No-Hit Challenge (hidden until the game is beaten)
- [ ] Call `Settings.mark_beaten()` from the real ending
- [ ] Save more state as regions are added (keys, petals, side quests)

## Directional moves (headless-tested, feel untested)
- [x] W / S aim keys
- [x] Lantern up swing and downward pogo
- [x] Open Hand Rising Palm
- [x] Open Hand Coin Toss 8-way aim
- [ ] Aim the Lantern Flash or Palm Push shockwave

## Story pass (never run in Godot)
- [x] Hub arrival cutscene (Nim, seven keyholes; no Reflection text on purpose)
- [x] Greed: entry, shrine and weight lines from Nim
- [x] Post-Greed and post-Sloth hub dialogue
- [x] Reflection figure grows with regions cleared (visual only, never explained)
- [ ] Gluttony onward, Mirror Gate, endings, side quests

- [ ] Playtest Greed's road-to-canopy ascent, upper crossing and drop onto Gold Ridge; also test Vault Route, Sloth's loft stair and sky route, both mini-bosses and both exits.
- [ ] Playtest seal gates: collect both seals in each region in either order, then the boss fight starts.
- [ ] Playtest Gluttony: Fullness and Stuffed, both seals, the Host's three phases, the Table Exit.
- [ ] Build Devour Style for the Hollow Spoon.
- [ ] Playtest Devour and Tempo styles: Tab swap, Scoop/Gulp/Spit/Open Wide, Tempo beat timing and guard.
