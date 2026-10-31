# What the Water Keeps

A dreamy 2D Souls-like platformer. Cute on the surface, with a much deeper meaning underneath.

Lumi, a small lantern-carrying wanderer, wakes beside a still pond. Seven doors lead to seven lands, each built from one of the seven sins. Every boss was once something kind. The last boss is Lumi's own reflection, and the only way to win is to stop fighting.

Target: a playable game on itch.io, in the spirit of Hollow Knight and Blasphemous, but soft, pastel and storybook.

## For AI agents: start here

1. Read this README fully.
2. Read `docs/game-bible.md`. It is the source of truth for story, dialogue, regions, bosses, movesets, UI and tone. Do not invent lore or rename things. If the bible and the code disagree, ask the user which is right.
3. Work on a branch, never directly on `main`. Keep commits small.
4. Be honest about verification. If you could not run the game in Godot, say so. Do not claim something works unless it was tested.
5. Ask before large changes (new systems, remapping controls, restructuring files).

### Hard rules from the user

- **Sign dialogue behaviour is intended and final.** Pressing E near a sign opens its dialogue, and walking away closes it automatically. Do not change this.
- The game has **no buffs**. Mechanics punish you with debuffs when you ignore a region's lesson. Do not add stat-boost pickups.
- Keep the tone gentle. Quiet over loud. Sad, never edgy. Lust is portrayed as obsessive longing only, nothing sexual.
- Keep code short and readable. Wrap long lines.
- **Everything must be readable at a glance.** All on-screen text uses a dark outline (`font_outline_color` 0.12, 0.10, 0.24) so it works on any background. Minimum sizes: HUD text 17+, world labels 17, dialogue 24, prompt 23. Muted menu text must stay above (0.8, 0.8, 0.9). Do not add pale text on pale sky without an outline.
- **Colour rule** (`scripts/palette.gd`): every solid thing must contrast at least 3:1 with what is behind it. Ground is the darkest thing in a scene. Characters get a dark outline or a light rim. New regions add their ground and sky colours to `palette.gd` and check the contrast before drawing anything. Pale-on-pale (the old Wake ground on the Wake sky was 1.1:1) is a bug.

## Current status: Prototype 02 (Wake → Still Pond → Greed)

Implemented in code:
- Lumi movement, jump, dash, lantern swing, health and healing
- Four Wake tutorial signs and the Little Jelly
- Old Moss tutorial boss with telegraphed head-lunge, rolling shell and spore-fan attacks; below half health he adds an aimed spore burst
- The Wind Ribbon appears after his defeat
- Wind Ribbon unlocks dash and sets the Wake checkpoint
- A post-boss gap intended to require jump + dash before the first door
- The Still Pond hub with seven doors, bench, altar, Memory Tree, Mirror Gate placeholder, Marl and Orrin
- Greed region with proximity-collected coins, weight penalties, offering shrines, lore tablets, and a Featherweight Charm that unlocks double jump
- Greed encounters: patrolling Greedy Mites, hopping Penny Pips that stick coins to Lumi (dash to shake them off), and Gilded Blossoms that telegraph and spit slowing sap
- Coin Guard mini-boss in the buried mint hall: an 8-hit shield with visible pips, a close-range telegraphed rushing slam, 48 health with a screen-fixed HUD bar, and a physical Vault Seal pickup on defeat. The seal is collected with E and is saved separately from the boss defeat, so leaving it behind does not grant it
- The Collector boss (never run, values are guesses): Coin Rain and belly slam, then below 66% health he swallows his coin mountain and grows (faster if Lumi carries gold) while the arena's left wall creeps inward, then below 33% he lunges for Lumi's purse. A grab with gold steals it all and heals him; with empty hands it whiffs and leaves him open. Offering bowls hurt and shrink him. Defeat plays the bible's lines, sets the Open Hand and Gold Key flags and clears Greed, which returns Lumi to the hub with one more key
- Wake → Hub → Greed → Hub handoff using the same Lumi instance
- Hub arrival positioned beside the Greed door without the bench/NPC stealing the first interaction
- Colour pass: deeper Wake ground, Greed now draws its ground and platforms (it had none), outlines on Lumi, the Little Jelly, Old Moss and The Collector (never run in Godot)
- Title, pause, settings and controls menus (Esc), a lantern HUD meter (flame shrinks with health, oil drops for heals), and saved Reduce Shake / Gentle Mode / Fullscreen options. Never run in Godot
- Wake split into four rooms with a locked camera that slides to the next room when Lumi crosses the room edge (never run in Godot)
- Hub: platforms rebuilt so every step is jumpable (55px max, no gaps, nothing hanging over walkways), Mirror Gate marker on the pond platform, hub killbox at y=900
- The Open Hand (Offering Style) as a real fighting style, full kit, unlocked by beating The Collector (never run in Godot, all numbers are guesses). Tab swaps between Lantern Swing and Open Hand:
  - Palm Push J,J,J (7/7/10, third hit sends a 6 damage shockwave 3 tiles), wide and slow, 15% faster with an empty purse
  - Offer: carried gold is spent as coins (10 gold each) for +1 damage per coin (max +10) and loses weight at once
  - Wide Offering (hold K 0.6s, release, 24), Falling Petals (J in air, 14, landing ring pushes enemies out), Gentle Rush (dash then J, 8, pushes back)
  - Coin Toss (L, 20 Glow, up to 5 coins at 3 each, or one soft orb), Open Palm guard (I, 0.25s, perfect in the first 0.12s gives Glow and returns Moss spores at 2 damage), Everything Given (O, 100 Glow, hits everything on screen for 12 plus 1 per coin)
  - Glow: gained from hits and perfect guards, shown as five petals around the HUD lantern
- Lantern Swing extras (never run in Godot): heavy K (22, wind-up, knockback), Lantern Flash L (30 Glow, 6 damage and a 1.5s stun on small enemies in 150px), guard I (0.25s, perfect guard gives Glow), Warm Light O (100 Glow, 40 damage and push in 260px). Jelly, Dust Bunny and Puddle Sprite can be stunned
- Lantern Swing combo: J,J,J = 8/8/12 (third hit lunges), air swing 9, dash swing 10 (never run in Godot)
- Slumber Hollow (Sloth), the second region, never run in Godot (all numbers are guesses). Door opens in the hub once Greed is cleared:
  - Drowse: builds while Lumi stands still (+1 per second) or moves with unlit lanterns within 700px (+0.5 per second). 25: Nim's line. 50: "You put it off again", vignette and 15% slower (stand-in for the bible's 0.1s input delay). 100: Lumi sleeps 3 seconds, then drops to 60. Lighting a lantern gives -20. Gentle Mode halves the build
  - Souls-like: three hammock benches (rest saves your spot, refills hearts and heals, respawns enemies), enemies respawn when you die, killed trails vanish, fog gate and lock wall at the boss, death in the arena resets the fight, falling in the pit returns you to the last bench
  - Platforming: bobbing pillows over a pit (the 230px gap needs double jump or dash), a six-step hammock climb to a high ledge, drop down to the boss
  - Enemies: Napping Nimbus (drifts, drops sleep spores), Snoozle Snail (slow, leaves drowsy trails), Hammock Spider (drops on Lumi when she stands still near it)
  - The Dreamer (420 HP, bible says 800): Lullaby notes then a yawn that lowers her into reach, Pillow Fall (pillows crush, then become platforms; lantern posts appear), Covers Over (arena dims, climbable walls appear, Snail Grips are granted, strike the lantern-heart while it glows. The heart hangs by one wall per 7s round and drifts to the other; while clinging, attacks and throws point away from the wall so they can reach it. Headless-tested that both styles hit it)
  - Snail Grips (wall climb): hold toward a climbable wall to cling, hold jump to climb. Only walls in the `climbable` group work
  - Rewards set flags only: Hourglass Shard (Tempo Style is not built yet) and Dusk Key
- Story pass (never run in Godot): a short hub arrival plays at the start (Nim, seven keyholes, seven doors), Nim comments in Greed (entry, first shrine, getting heavy), and after Greed and after Sloth Nim says a line in the hub. The Reflection is never named or spoken about in text: it is only a figure in the pond that the player can notice (eyes follow, brighter with each clear). Do not add dialogue that explains it Nim's post gives gameplay hints. See bible Part 6
- Directional moves (headless-tested only for hit and aim logic): W / S are new aim keys. Lantern: W + J upward swing (9), S + J in the air downward pogo (9 and a bounce). Open Hand: W + J Rising Palm (9). Coin Toss throws in 8 directions with W / A / S / D (straight shots, fan of coins around the aim), with an aim dot when Glow is enough. Headless Godot 4.6 was used to check that scripts load and these moves hit/aim correctly, not how they feel
- Difficulty, harsher debuffs, bench saves and a secret challenge (headless-tested for logic, never played):
  - New Game asks for Gentle, Normal or Hard. Damage: about 0.75x / 1x / 1.5x per hit (fractions carry over). Debuffs build 0.5x / 1x / 1.4x. Heals: 4 / 3 / 2. Falling asleep lasts 3 / 4 / 5 seconds. The Gentle Mode toggle in Settings still works and acts as Gentle
  - Drowse now costs: 50 = 20% slower, jump -8%, +1 damage per hit. 80 = 35% slower, jump -15%, +1 damage, no healing. 100 = asleep (4s on Normal), sleepers take +1 damage, then Drowse drops to 70 (was 60)
  - Weight (Greed): speed and jump both drop up to 50% (felt weight 0.7 caps the speed at -35%). From felt weight 0.5 hits do +1 damage, from 0.6 no dash and no double jump. The HUD names the tier
  - Saving is bench-only: the hub bench and Sloth's hammocks write `user://save.json`. Title has Continue (only if a save exists) and New Game. It stores difficulty, where Lumi rested (hub or Sloth), heals, style, unlocked styles, dash / double jump / wall climb, regions cleared, whether the Charm was taken and which bosses are beaten. Pause has Return to title (two presses)
  - Secret No-Hit Challenge: hidden on the difficulty screen until `Settings.mark_beaten()` has run. Any hit that gets past a guard ends the run (a RUN ENDS screen, then title). It never writes a save. The ending is not built, so nothing calls `mark_beaten()` yet. To try it now, add `[meta]` and `game_beaten=true` to `user://settings.cfg`
- Pit recovery, checkpoint-aware death respawn, visible Wake boundaries, hit-stop and camera-shake feedback

Still incomplete:
- Slumber Hollow is untested. Missing from it: the Unwound Clock quest, Memory Petals, a Soft Shortcut, hidden areas, music, the bible's 0.1s input delay (approximated by slowing)
- Playtesting and tuning The Collector and the Open Hand. The Gold Key is only a flag. Lantern Swing still lacks the dash attack passing through small enemies. The Open Hand does not yet clean sticky coins off Lumi, return Collector coins with its guard, or use the Altar for swapping
- Other region implementations, full fighting styles, memory petals, the map/loadout/Memory Tree/keepsake screens, key remapping, audio sliders, music and imported art
- Full hub-door progression and final Mirror Gate
- Runtime verification of the current transition loop and combat feedback

The scripts build most objects dynamically and visuals are still mostly simple primitives. Treat this as a work-in-progress prototype, not a finished game.

## Tech

- Godot 4.7 or newer (project feature tag), GDScript, GL Compatibility renderer, 1280x720
- No imported assets yet. All visuals use `_draw()` primitives, and the level is built in code.
- Windows or Linux

Run: open `project.godot` in the Godot Project Manager and press F5.

## Project layout

| Path | What it does |
|------|--------------|
| `project.godot` | Settings and input map |
| `scenes/main.tscn` | One node with `main.gd` attached. Everything else is created in code |
| `scripts/main.gd` | Level building, HUD, dialogue, interactables, killbox, camera limits, checkpoint |
| `scripts/player.gd` | Lumi: movement, dash, attack, heal, damage, drawing |
| `scripts/little_jelly.gd` | Tutorial enemy: patrol, contact damage, knockback |
| `scripts/greed.gd` | The Gilded Garden: level, gold and weight, shrines and bowls, Collector fight flow and rewards |
| `scripts/collector.gd` | The Collector boss: phases, attacks, growth, purse grab, drawing |
| `scripts/menu_overlay.gd` | Title, pause, settings and controls menus. Lives on the root as `MenuOverlay`, pauses the tree while open |
| `scripts/game_settings.gd` | Saved options (`user://settings.cfg`), Gentle Mode toggle, the `game_beaten` unlock flag |
| `scripts/run_state.gd` | Current run: difficulty, damage / debuff / heal scaling, no-hit challenge flag |
| `scripts/save_game.gd` | Reads and writes the bench save (`user://save.json`) |
| `scripts/palette.gd` | Shared colours and the contrast rule |
| `scripts/lantern_meter.gd` | HUD health lantern, reads the `player` group |
| `scripts/open_hand.gd` | Open Hand style: combo, Offer, heavy, air, dash attack, Coin Toss, guard, Overture. Child node `OpenHand` of Lumi |
| `scripts/lantern_kit.gd` | Lantern Swing extras: heavy, Lantern Flash, guard, Warm Light. Child node `LanternKit` of Lumi |
| `scripts/palm_shot.gd` | Moving palm waves (shockwave, coins, orbs, reflected spores) |
| `scripts/coin_guard.gd` | Greed mini-boss in the Vault (48 HP, 8 shield, slam deals 2) |
| `scripts/greedy_mite.gd` | Greed mite enemy |
| `scripts/penny_pip.gd` | Hopping Greed enemy; sticks a coin to Lumi on contact, shaken off with dash |
| `scripts/gilded_blossom.gd`, `scripts/gilded_sap.gd` | Stationary Greed plant and its telegraphed, slowing sap projectile |
| `scripts/dozy_warden.gd` | Slumber Hollow mini-boss on the sky route (70 HP, slam, sleep-note yawn) |
| `scripts/sloth.gd` | Slumber Hollow: level, Drowse, lanterns, benches, enemy spawns, Dreamer fight flow and rewards |
| `scripts/dreamer.gd` | The Dreamer boss, plus `pillow.gd` and `dreamer_heart.gd` |
| `scripts/sleep_spore.gd` | Sleep spores and lullaby notes (they add Drowse) |
| `scripts/nimbus.gd`, `snoozle_snail.gd`, `hammock_spider.gd`, `drowsy_trail.gd`, `bob_platform.gd` | Sloth enemies, the snail's trail and bobbing pillow platforms |
| `scripts/story.gd` | Every story beat as `[text, seconds]` lists, plus `Story.play()` that shows them in a scene's dialogue box |
| `scripts/reflection.gd` | The pond Reflection: mirrored Lumi that follows with its eyes and changes with regions cleared |
| `scripts/collector_coin.gd` | Coins he throws: they hurt while falling, then become gold pickups |
| `docs/game-bible.md` | Full design reference (story, regions, bosses, movesets, art, sound, UI) |

## Controls (prototype)

| Key | Action |
|-----|--------|
| A / D | Move |
| W / S | Aim up / down. Combined with A / D it aims in 8 directions (new keys, added for directional moves) |
| Space | Jump |
| Left Shift | Dash |
| J | Attack. Hold W for an upward swing (9). Hold S in the air for a downward pogo swing (9, bounces Lumi up on a hit). Open Hand: W + J is Rising Palm (9) |
| Q | Heal |
| E | Interact |
| Esc | Pause menu / back |
| Tab | Swap fighting style (after Greed) |
| K | Heavy. Lantern: 22 damage after a short wind-up. Open Hand: Wide Offering, hold 0.6s then release |
| L | Skill. Lantern Flash 30 Glow, or Coin Toss 20 Glow, thrown in the 8-way aim direction (nothing held = the way Lumi faces) |
| I | Guard (0.25s, perfect in the first 0.12s) |
| O | Overture, 100 Glow. Lantern: Warm Light. Open Hand: Everything Given |

The bible's final control scheme differs (heal on H, Q cycles fighting styles). The user chose Tab for style swapping so Q stays Heal. K, L, I and O match the bible. Ask before remapping.

## Level reference (Wake)

World units are pixels. Ground top is y=610.

| Thing | Position |
|-------|----------|
| Player start / first respawn | (240, 570) |
| Signs | x = 355, 560, 820, 1100 |
| Wind Ribbon (and checkpoint) | x = 3750 |
| Dash gap | x = 3900 to 4100 |
| First door / Hub entrance | x = 4380 |
| Boundary walls | x = 55 and x = 4600 |
| Killbox | y > 900 |

### Wake rooms

Rooms are chosen by Lumi's x. The camera is locked to the room's camera range and slides over on crossing. A camera range must be at least 1280 wide, so short rooms borrow width from a neighbour. Change them in `WAKE_ROOMS` in `main.gd`.

| Room | Lumi is in it for x | Camera range | Holds |
|------|---------------------|--------------|-------|
| meadow | 0 to 1280 | 0 to 1280 | signs 1 to 4, Little Jelly |
| path | 1280 to 2160 | 880 to 2160 | empty walk to the arena |
| old_moss | 2160 to 3440 | 2160 to 3440 | Old Moss arena |
| ribbon | 3440 to 4700 | 3420 to 4700 | Wind Ribbon, dash gap, first door |

## Level reference (Slumber Hollow)

| Thing | Position |
|-------|----------|
| Start / first bench / hub exit | x = 150 / 180 / 80, ground top y=600 |
| Start ground | x = -100 to 900 |
| Bobbing pillows over the pit | x = 960 to 1300 (killbox y > 900) |
| Double-jump gap | x = 1300 to 1530, landing at y=500 |
| First ledge and second bench | x = 1790 to 2300, bench at 1900 |
| Hammock climb | six 110px platforms, x = 2390 to 3350, tops from y=490 up to y=240 |
| High ledge | x = 3410 to 3960, top y=240 |
| Pre-boss bench | x = 3830 (under the ledge) |
| Dozy Warden arena ledge | x = 4200 to 4840, top y=120 |
| Boss marker, lock wall, end wall | x = 4440, 4180, 5400 |
| The Dreamer's fight bounds | x = 4200 to 5350 |
| Phase 3 climb walls | x = 4420 and 5110, heart at (5030, 210) |

Platforms are listed in `PLATFORMS` in `sloth.gd`. Steps up are 55px or less, gaps are 60px or more.

## Level reference (Greed arena)

| Thing | Position |
|-------|----------|
| Start marker for the fight | x = 2130 (E to approach) |
| Coin Guard arena floor | x = -2050 to -800 (1250px wide) |
| Left lock wall during the fight | x = 1800, creeps inward as he grows (up to 150px) |
| Offering bowls | x = 2230 and x = 2660 |
| The Collector / his coin mountain | x = 2500 / x = 2580 |
| Collector arena floor and end wall | x = 1890 to 3000 (1110px wide) / x = 3000 |

The Collector and Dreamer now have broader combat bounds, and the Coin Guard's mint floor and Dozy Warden's upper ledge provide more room to maneuver. Their visible arena markings follow those wider spaces; the changes use existing region terrain and do not add obstacles inside the fights.

### Greed route layout

Greed has a lower road, an upper canopy floor and two optional branch routes. The map keeps the existing soft, golden storybook palette, with playable surfaces drawn as broad stone ledges with horizontal tops.

- The main road runs near y=570.
- The canopy entrance starts at x=930. Five flat treads rise westward by 40px each; Lumi turns onto one broad, flat canopy floor at y=330 and crosses east above the road. The canopy uses one-way collision, so Lumi can jump up through it and the lower road stays open underneath. The floor ends above the Gold Ridge approach near x=1360, where Lumi can drop onto the Ridge.
- A shrine sits on the road before the canopy climb, and another sits on the treasury floor before the Coin Guard. Both let Lumi offer carried gold before the next route section.
- The Gold Ridge is four broad ledges with 40px rises and 70px flat-edge gaps. It leads to the seal at x=1925, y=380, then drops back to the Collector road.
- The western Vault Route begins beside the road at x=250. Six broad ledges rise over the old garden wall in 50px steps, then descend into the treasury floor and Coin Guard arena. Both ends of the route are marked with a subtle direction cue.
- Enemy encounters sit on the route itself: Mites patrol the road and vault approach, Pips hop from the lower path and canopy/vault ledges, and Blossoms hold high shelves above the Gold Ridge and vault climb. Pips telegraph before hopping; Blossoms aim a visible line before launching sap.
- The Coin Guard is the Vault's mini-boss. Defeating it drops a visible Vault Seal beside the mint gate. Lumi must collect it; it is not silently added on defeat. The saved boss state preserves an uncollected drop.
- The treasury's hidden upper nook has a glint near its first shelf. The next shelf sits 90px above it, so the optional 35-gold cache requires Double Jump.

The route platforms use the same shapes for collision and drawing. Their landing tops are level; only the sides are beveled. The route shelves are one-way platforms, keeping drops and upward passage clear. Keep rises at 55px or less, leave 50px of headroom, and keep flat-edge gaps at 60px or more. Only the closest nearby interaction label is shown at a time, to keep the route visible. Weight can lower Lumi's jump; shrines are placed before the canopy climb, on the treasury approach, and below the Gold Ridge. Shrine bowls and the Featherweight Charm have distinct world sprites; mint and Collector arenas use floor inlays and simple stone framing rather than extra collision clutter.

## How the code works

- Hub platforms live in `PLATFORMS` in `hub.gd` (used for both collision and drawing). Lumi's jump is about 77px, so keep every step up at 55px or less and leave 50px of headroom under floating platforms.
- The camera is found through the `game_camera` group. Runtime-created nodes get auto names like `@Camera2D@2`, so `get_node("Camera2D")` returns null; never look it up by name.
- Sloth: `sloth.gd` is in group `drowse_holder`; spores and trails call `add_drowse()`. Enemies are rebuilt from `SPAWNS` by `_spawn_enemies()` on bench rest and death. The player emits `died` when it respawns. `player.fall_asleep(seconds)` freezes input.
- Both style nodes (`OpenHand`, `LanternKit`) expose `block_hit()`; enemies that can be stunned have `stun(seconds)`; to make a new enemy stunnable add `stun_time` and a check at the top of its `_physics_process`.
- Wall clinging: holding toward the wall faces Lumi into it, so `player.attack_facing()` returns the side away from the wall while `clinging`. Lantern swings, Open Hand swings and `aim_vector()` all use it. Do not read `facing` directly for attack direction.
- Styles: `player.gd` holds `style`, `unlocked_styles` and `glow`. `greed.gd` calls `unlock_style("open_hand")` after the Collector. While `style == "open_hand"` the `OpenHand` node reads the combat inputs and `player.gd` skips the Lantern swing. Guard works through `player.take_damage` asking `OpenHand.block_hit()`. Gold is read from nodes in the `gold_holder` group (Greed) and spent with `spend_gold()`. Moss spores join the `enemy_projectile` group so a perfect guard can return them.
- Wake rooms: `_update_wake_room()` in `main.gd` runs each frame while `current_region == "wake"`. A respawn that jumps rooms snaps the camera instead of sliding. Rooms have no names on screen because the bible gives none.
- Story: add or edit text only in `story.gd`, and only text that is in the bible. Hard rule: never spoil or point at the Reflection in text. Players find out slowly. `Story.play(scene, panel, label, lines)` shows a beat and sets meta `story_busy`, which makes the scene's interact code hide the E prompt. Playing a new beat cancels the old one. `hub.gd` stores `pending_story` when a region is cleared and plays it when the hub becomes active.
- Menus: `main.gd` adds `MenuOverlay` to the root once. Esc opens pause only when the tree is not already paused (hit-freeze owns that pause). Options are read from `game_settings.gd` (`Settings.reduce_shake`, `Settings.gentle_mode`). Return to title is `main.restart_to_title()`: it frees the hub and region scenes (they live on the root), then reloads the scene and tells the overlay to show the title.
- Run state and saves: difficulty lives in `run_state.gd` (read `RunState.damage()`, `debuff_scale()`, `max_heals()`, never `Settings.gentle_mode` directly). `main.gd` is in group `game_main`; scenes call `get_tree().call_group("game_main", "save_game", where, respawn)` when Lumi rests. Each region has `save_state()` / `apply_save()`; `main.save_cache` holds the sections of regions not loaded this session. Add new saved facts to `save_game()` and `continue_game()` in `main.gd` plus the region's two functions. The arrival story starts from `main.begin_new_game()`, not `_ready`. Debuffs reach the player through `player.vulnerable`, `heal_blocked` and `weighed_down`, set by the region each frame and cleared when it goes inactive.

- `main.gd` keeps a list of `interactables` (dictionaries with `node`, `message`, `kind`, `used`). `_process` finds the nearest one within 95px, shows the E prompt and handles opening and closing dialogue.
- New interactables go through `_make_marker()` and `interactables.append(...)`.
- Status messages go through `_show_status()`. Only the newest message restores the HUD.
- `player.gd` emits `health_changed`, `heals_changed` and `status_changed`. `main.gd` listens and updates the HUD.
- Enemies join the damage system by having a `take_damage(amount)` method. The player's attack area calls it.
- The Collector is on collision layer 2 with no mask and is moved by code, so he never shoves Lumi. Lumi's attack area looks at layers 1 and 2.
- `greed.gd` owns gold. `collector.gd` calls `steal_all_gold()` and reads `carried_gold` on it, and falling coins call `add_gold()`.

## Roadmap (suggested order)

1. Playtest and stabilize Wake → Still Pond → Greed → Still Pond.
2. Playtest and tune The Collector and the Open Hand (both never run). Next: playtest Sloth, then the Gluttony region (needs Wall Climb).
3. Connect region-clear rewards to hub door unlocks and gadget progression.
4. Build the remaining six regions and their bosses, keeping the game bible as the source of truth.
5. Add the Mirror Gate, Memory Path, final fight and both endings.
6. Add side quests, Memory Petals, then polish art, music and sound.

## Design pillars (short version)

- Every mechanic is also a moral lesson. Ignore it and the world answers back.
- Each artifact is the virtue that answers its sin, and unlocks a distinct fighting style.
- Cute on the surface. Small uncanny details grow as the game goes on.
- The final fight is unwinnable by fighting. Standing still for about 8 seconds lets the player accept themselves (good ending). Striking during the 5 to 6 second cutscene window leads to the bad ending.

## Testing notes for agents

- Godot is often not installed in agent sandboxes. If it is not, say so, and do a syntax check instead, for example `pip install gdtoolkit` then `gdparse scripts/*.gd`.
- `gdparse` is NOT enough: it missed three scripts that Godot refuses to load (an empty function body, `:=` on an untyped value, a member that shadows an Area2D property), and one of them made Lumi invincible. Godot can be downloaded headless from GitHub releases (`Godot_v4.6-stable_linux.x86_64.zip`, works in the sandbox). Run `godot --headless --path . -s <script.gd>` with a script that loads every file in `scripts/` and prints any that fail, then one that instantiates `scenes/main.tscn`, calls `_transition_to_hub/greed/sloth` and hits Lumi. Headless runs prove scripts load and damage works, not that the game feels right.
- Ask the user to playtest and report exact errors or feel problems.
- Known rough spots: the dash gap width is tight and may need tuning. The Collector's health (360), timings, growth rate and squeeze are untested guesses.
- Runtime testing is still required after the progression and transition changes.

## Expanded, non-linear levels (by design)

- Greed and Sloth are larger with branching routes: Greed has a Vault Route (left, to the Vault and Coin Guard) and a Gold Ridge (right). Sloth has a loft stair (left) and a sky route (right) to the Dozy Warden.
- Beating a region does not teleport the player home. They must crawl out through the Vault Exit (Greed) or Dream Exit (Sloth, at the far end of the left loft stair), which return to the hub at about (1200, 375). This is intentional.
- "Coin Guard" and "Dozy Warden" are prototype names, not in the bible yet. Their rewards are undefined.
- Extra platforms live in `EXTRA_PLATFORMS` in `greed.gd` and `sloth.gd`; same step and gap rules as above.
- Headless-tested only (jump hops, mini-boss flow, exits, saves). Not played in the Godot editor.

## Seal gates and pickup sprites

- Each boss approach is gated by two seals (`SEALS_NEEDED`), one from each optional branch, collectable in either order:
  - Greed: the Coin Guard drops the "vault" seal; a pickup at the end of the Gold Ridge is the "ridge" seal.
  - Sloth: the Dozy Warden drops the "sky" seal; a pickup at the top of the loft stair is the "loft" seal.
  Pressing E at the boss marker with fewer than 2 shows the seal count and does not start the fight. Seals are saved at benches (`seals` in each region's save).
- "Seal" is a prototype word, not in the bible.
- Pickups (coins, gold, seals) are now drawn: coin and seal sprites in `greed.gd` `_draw`, seal in `sloth.gd` `_draw`. Before, they were label-only.
- Greedy Mites now turn around at ledges instead of walking off.
- Rendered screenshots can be taken headless with `xvfb-run` and `--rendering-driver opengl3`.

## The Endless Table (Gluttony), prototype

- Region 3, `scripts/gluttony.gd`. It extends `sloth.gd` (HUD, dialogue box, seals, bench saving) with its own level, mechanic and boss. Unlocked in the hub once Slumber Hollow is cleared.
- **Fullness:** eating a cake heals 1 heart and adds 25 Fullness. At 100 Lumi is Stuffed for 20s (no dash, swings 25% slower, healing halved, a little slower). Moving burns Fullness off. When Lumi has 3 hearts or fewer, eating is mindful: heals 2 and adds no Fullness. Bench rest clears Fullness and refills the cakes.
- **Enemies:** Crumb Swarm (`crumb_swarm.gd`, scatters when hit), Jelly Gulper (`jelly_gulper.gd`, swallows and adds Fullness), Cutlery Sprite (`cutlery_sprite.gd`, winds up then pokes).
- **Branches:** the Pantry Loft (high stair, a seal on the shelf) and the Syrup Cellar (a pit with the Cutlery Knight mini-boss, `cutlery_knight.gd`, which drops the second seal). Two seals open the Host's fog. "Cutlery Knight", "Pantry Loft", "Syrup Cellar" and "seal" are prototype names, not in the bible.
- **The Host** (`host.gd`, 420 HP, bible says 900): Phase 1 lobs snacks that hurt and add Fullness; Phase 2 adds sagging pies (`pie_platform.gd`) and a table-slam shock wave to jump; Phase 3 he grows and sends jaw walls with a gap (`host_hazard.gd`), and he can only be hurt while gaping afterwards.
- **Rewards:** Hungry Wind Scarf (`player.can_super_dash`: longer, faster dash, saved), Honey Key flag, and the Hollow Spoon, which unlocks Devour Style. The Table Exit sits at the end of the pantry shelf, and the player must walk out.
- Player additions: `dash_blocked`, `attack_speed_mod`, `heal_amount_mod`.
- Headless-tested: scripts load, hub unlock, eating (healthy and mindful), Stuffed effects, seal gate, mini-boss seal drop, bench save, full Host fight through all phases by direct damage, rewards, saves, exit, and platform hops. Rendered screenshots show every enemy, pickup and the seal. **Not played in the editor**; Host timings and damage numbers are guesses.

## Devour Style and Tempo wiring

- `scripts/devour_style.gd` (Hollow Spoon, from the bible's Devour Style). Unlocked by The Host and equipped with Tab. Built: Scoop (J x3, 9/9/13, the third pulls enemies in), Gulp (hold K 0.4s, 26 damage, swallows enemies under 20 HP as a Pip), Spit (L, 15 Glow, fires Pips: 12 each, 3 Pips = one 45 damage beam), Open Wide (I, absorbs projectiles, no melee block) and absorbing projectiles with the Scoop. Taste: up to 3 Pips, a fourth makes Lumi Stuffed for 1.5s. The Host's snacks join the `enemy_projectile` group so Devour can swallow them instead of being fed. **Not built:** Slurp Drop, Chomp Dash, the Overture.
- **Fix:** `tempo_style.gd` (Hourglass Shard) was never attached to the player or unlocked. `player.gd` now creates `TempoStyle` and `DevourStyle`, Tempo's guard goes through `take_damage`, and defeating the Dreamer calls `unlock_style("tempo")`. Saves restore both styles from the saved style list, and old saves with the hourglass get Tempo back. Style names for the Tab status line live in `STYLE_NAMES` in `player.gd`.
- Headless-tested: both styles load and unlock, Scoop absorbs projectiles into Pips, the fourth Pip Stuffs, and Spit's beam does 45. Gulp, Open Wide, Tempo's moves and all feel are untested. Not played in the editor.
