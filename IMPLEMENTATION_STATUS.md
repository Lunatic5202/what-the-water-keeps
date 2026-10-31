# Implementation Status

**Last updated:** 2026-10-31  
**Default branch at audit start:** `main`  
**Audit branch:** `audit/integration-docs-2026-10`  
**Engine target:** Godot 4.7+ (from `project.godot` feature tag)

This file separates source implementation from verification. A feature marked implemented is present in source; it is not automatically considered playtested.

## Region status

### The Wake — implemented in source
- Lumi movement, jump, dash, lantern combat, health and healing.
- Four tutorial signs, Little Jelly and Old Moss encounter.
- Wind Ribbon unlocks dash and sets the Wake checkpoint.
- Four room camera layout, boundaries, killbox/pit recovery and post-Ribbon dash gap.
- Title, pause, settings and controls menus; lantern health meter and Glow petals.

### The Still Pond — implemented in source
- Seven-door multi-tier hub, bench, Altar of Hands, Memory Tree, Nim's Lantern Post and Mirror Gate placeholder.
- Marl and Orrin; silent Reflection visual.
- Hub transitions and region unlocks through Greed, Sloth and Gluttony.

### Greed — implemented in source
- Weight, carried gold, shrines, offerings and lore.
- Main route, canopy/Gold Ridge route and buried vault route.
- Greedy Mites, Penny Pips and Gilded Blossoms.
- Coin Guard mini-boss and physical Vault Seal.
- Two-seal Collector gate; three-phase Collector fight and offering interaction.
- Open Hand manual in vault, Featherweight Charm double jump, Gold Key and Vault Exit.

### Sloth — implemented in source
- Drowse, lanterns, benches, death/respawn and enemy respawns.
- Snoozle Snails, Hammock Spiders and Napping Nimbus.
- Pillow gap, loft route, sky route and climbable walls.
- Dozy Warden mini-boss and second seal on loft route.
- Two-seal Dreamer gate; three Dreamer phases including moving lantern-heart.
- Hourglass Shard, Tempo unlock, Snail Grips wall climb, Dusk Key and Dream Exit.

### Gluttony — implemented in source
- Fullness and Stuffed, food pickups and mindful eating.
- Crumb Swarm, Jelly Gulper and Cutlery Sprite.
- Pantry Loft and Syrup Cellar branches; Cutlery Knight mini-boss and two seals.
- Two-seal Host gate and three boss phases.
- Hollow Spoon / Devour unlock, Hungry Wind Scarf / Super Dash, Honey Key and Table Exit.

### Not implemented
- Envy, Lust, Wrath and Pride regions.
- Their bosses, mini-bosses, gadgets, styles and region-specific debuffs.
- Mirror Gate encounter, true/bad endings, credits and side quests.
- Full memory-petal progression and final UI screens.

## Combat styles

| Style | Source status | Outstanding work |
|---|---|---|
| Lantern Swing | Base combo and extra moves wired | Dash attack through small enemies; balance and playtest |
| Open Hand / Offering | Full prototype kit wired; unlocked from Greed vault manual | Sticky-coin cleanup, returning Collector coins with guard, Altar loadout |
| Tempo | Tick-Tock, Hour Strike, prototype Pendulum Drop, beat bonus, guard/counter and Stopwatch wired | Skip, second Pendulum hit, boss slow, Overture; timing and feel |
| Devour | Scoop, Gulp, Spit, Open Wide and Taste/Pips wired | Slurp Drop, Chomp Dash, Overture; normal playtest |

## Shared systems
- Gentle / Normal / Hard difficulty and Gentle Mode.
- Weight, Drowse and Fullness debuffs.
- Bench-only JSON saves, Continue and Return to Title.
- Checkpoint-aware death respawn.
- Glow, five-petal HUD, title/pause/settings/controls menus.
- Hit-stop and camera shake.

## Audit fixes on this branch

The following source changes were made on `audit/integration-docs-2026-10`:

1. **Devour Spit target de-duplication:** targets present in both `enemy` and `boss` groups are now damaged once per Spit.
2. **Tempo Stopwatch:** removed the ineffective write to the undeclared `tempo_frozen` property; Stopwatch now uses the enemy `stun(seconds)` interface.
3. **Sloth enemy registration:** enemies spawned by Sloth are now added to the shared `enemy` group, allowing group-based style skills to find them.
4. **Greed enemy stuns:** Gilded Blossom and Penny Pip now implement the same timed `stun(seconds)` interface used by Stopwatch.\n5. **Stuffed attack-speed penalty:** Open Hand, Tempo, Devour and Lantern heavy attacks now respect `attack_speed_mod`; Stuffed no longer loses most of its swing-speed penalty when changing styles.\n6. **Wall-cling attack direction:** Lantern heavy, Tempo/Devour guard visuals and Devour's Gulp charge visual now use `attack_facing()` so they point away from climbable walls.\n7. **Devour overflow lock:** the 1.5-second Stuffed state now blocks player actions globally and continues counting down even if Lumi switches styles.

These are static code changes. They have not yet been run in Godot, so runtime success is not claimed.

## Verification record

| Area | Existing repository evidence | Interactive Godot playtest |
|---|---|---|
| Wake / hub / Greed | Earlier source notes report headless checks; latest status still calls for full-loop testing | Not documented |
| Sloth routes / Dreamer / seals | Headless and screenshot checks reported | Not documented |
| Gluttony / Host / seals / rewards | Headless and screenshot checks reported; Host phase test used direct damage | Not documented |
| Devour / Tempo | Partial headless checks reported | Not documented |
| Audit fixes above | Static source review only | Not run |

### Required manual regression pass
- [ ] Launch with Godot 4.7+ and check for parser/runtime errors.
- [ ] Complete Wake → Hub → Greed → Hub → Sloth → Hub → Gluttony.
- [ ] Collect each region's two seals in either order and verify the gate.
- [ ] Defeat Coin Guard, Dozy Warden, Cutlery Knight and all three region bosses through normal combat.
- [ ] Test every boss reset after death/retreat and ensure hazards/lock walls are cleaned up.
- [ ] Test all four styles, including duplicate-target cases for Devour Spit and Stopwatch against all three regions' enemies.
- [ ] Save at each region's benches, continue, and verify all rewards/styles/seals/clears persist.
- [ ] Check dialogue closes on walking away from signs and region interactions.

## Engine and project constraints
- `project.godot` advertises Godot 4.7; use 4.7 or newer unless compatibility is deliberately verified.
- GL Compatibility renderer; 1280 × 720.
- Preserve the README's no-buffs, dialogue, tone, contrast and Reflection rules.
