# Implementation and Playtest Checklist

**Updated:** 2026-10-31  
**Meaning:** `[x]` = implemented in source or documented as complete; it does not imply an interactive Godot playtest. Manual verification is tracked separately.

## Core progression

- [x] Wake tutorial, four signs, Little Jelly and Old Moss.
- [x] Wind Ribbon dash unlock and checkpoint.
- [x] Wake → Still Pond transition and multi-tier hub.
- [x] Greed door and region transition.
- [x] Greed → hub return and clear/key unlock.
- [x] Sloth door and region transition after Greed.
- [x] Sloth → hub return and clear/key unlock.
- [x] Gluttony door and region transition after Sloth.
- [x] Gluttony → hub return and clear/key unlock.

## Regions

### Greed — The Gilded Garden
- [x] Weight and carried-gold system, shrines and offerings.
- [x] Greedy Mites, Penny Pips and Gilded Blossoms.
- [x] Canopy/Gold Ridge and buried vault routes.
- [x] Coin Guard mini-boss and physical Vault Seal.
- [x] Open Hand manual and Featherweight Charm.
- [x] Two-seal Collector gate, three boss phases, offering bowls and Vault Exit.
- [ ] Play the complete region in Godot; tune route readability and combat balance.

### Sloth — Slumber Hollow
- [x] Drowse and lantern reduction mechanic.
- [x] Snoozle Snails, Hammock Spiders and Napping Nimbus.
- [x] Benches, pillow gap, loft stair and sky route.
- [x] Dozy Warden mini-boss and loft seal.
- [x] Two-seal Dreamer gate and three boss phases.
- [x] Phase-three climbable walls and moving lantern-heart.
- [x] Hourglass Shard / Tempo unlock, Snail Grips and Dream Exit.
- [ ] Play the full region in Godot; verify wall-cling combat, enemy respawns and boss timing.

### Gluttony — The Endless Table
- [x] Fullness, Stuffed and mindful eating.
- [x] Crumb Swarm, Jelly Gulper and Cutlery Sprite.
- [x] Pantry Loft seal and Syrup Cellar branch.
- [x] Cutlery Knight mini-boss and second seal.
- [x] Two-seal Host gate and three boss phases.
- [x] Hollow Spoon / Devour, Hungry Wind Scarf / Super Dash and Honey Key.
- [x] Table Exit.
- [ ] Play the region normally in Godot; verify Host attack timing, jaw-wall gaps, platform collision and reward flow.

## Fighting styles

### Lantern Swing
- [x] J combo, directional up swing and downward pogo.
- [x] K heavy, L Lantern Flash, I guard and O Warm Light.
- [ ] Implement dash attack passing through small enemies.
- [ ] Playtest hitboxes, guard timing and Glow costs.

### Open Hand / Offering
- [x] Palm combo, Offer, Wide Offering, Falling Petals and Gentle Rush.
- [x] Coin Toss, Open Palm guard and Everything Given.
- [x] Unlock through the Greed vault manual; Tab style cycle.
- [ ] Clean sticky coins from Lumi.
- [ ] Return Collector coins with guard.
- [ ] Altar loadout selection.
- [ ] Playtest complete kit and tune guessed values.

### Tempo
- [x] Tick-Tock combo and beat bonus.
- [x] Hour Strike prototype.
- [x] Prototype Pendulum Drop.
- [x] Guard/counter and perfect-guard time slow.
- [x] Stopwatch enemy stun interface (audit fix on this branch).
- [ ] Implement Skip.
- [ ] Implement the second Pendulum Drop hit.
- [ ] Implement the bible's boss slow for Stopwatch.
- [ ] Implement Overture: Last Hour.
- [ ] Verify Hour Strike hold/release timing against the bible.
- [ ] Playtest beat timing, guard and counter.

### Devour
- [x] Scoop combo and third-hit pull.
- [x] Gulp and low-health enemy swallow/Pip.
- [x] Spit and three-Pip beam.
- [x] Open Wide projectile absorption.
- [x] Taste/Pips and Stuffed overflow.
- [x] Host snacks tagged as absorbable projectiles.
- [x] Spit de-duplicates targets present in both enemy and boss groups (audit fix).
- [ ] Implement Slurp Drop.
- [ ] Implement Chomp Dash.
- [ ] Implement Overture.
- [ ] Playtest Gulp, Open Wide, projectile absorption and Spit.

## Shared systems and UI

- [x] Gentle / Normal / Hard difficulty and Gentle Mode.
- [x] Weight, Drowse and Fullness debuffs.
- [x] Bench-only save, Continue and Return to Title.
- [x] Checkpoint-aware death respawn.
- [x] Glow meter and five-petal HUD.
- [x] Title, pause, settings and controls menus.
- [ ] Verify all save/load combinations after unlocking multiple styles and clearing multiple regions.
- [ ] Finish map, loadout, Memory Tree and keepsake screens.
- [ ] Add key remapping and audio sliders.
- [ ] Add final music, sound, imported art and animation.

## Documentation

- [x] README reflects current playable regions and styles.
- [x] Implementation status separates source state from verification.
- [x] Game bible Part 6 records prototype deviations without changing canon.
- [x] This checklist separates implementation from manual playtesting.

## Manual regression — required before calling this build playtested

- [ ] Run Godot 4.7+ and check parser/runtime output.
- [ ] Complete the full progression from Wake through Gluttony.
- [ ] Test each two-seal gate with seals collected in both orders.
- [ ] Test every mini-boss and boss through normal combat.
- [ ] Test death/retreat during each boss fight; confirm reset and cleanup.
- [ ] Test style cycling after each unlock and after Continue.
- [ ] Test Devour Spit against Coin Guard and Cutlery Knight; each should take one hit per Spit.
- [ ] Test Tempo Stopwatch against Greed, Sloth and Gluttony enemies.
- [ ] Test all region exits and return positions.
- [ ] Verify signs close when Lumi walks away.
- [ ] Check visual contrast, text outlines, HUD readability and platform collision.
