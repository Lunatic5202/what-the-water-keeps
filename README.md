# What the Water Keeps

A dreamy 2D Souls-like platformer: soft, pastel and storybook on the surface, with a deeper emotional story underneath.

Lumi, a small lantern-carrying wanderer, wakes beside a still pond. Seven doors lead to seven lands shaped by the seven sins. Every boss was once something kind. The final encounter is Lumi's own reflection, and the intended true ending is won by choosing not to fight.

**Current build:** playable prototype through Region 3 — The Endless Table (Gluttony). This is a work-in-progress, not a finished game.

## For contributors and AI agents

1. Read this README and `docs/game-bible.md` before changing gameplay or story.
2. The game bible is the source of truth for canon, story, region themes and intended movesets. Prototype adaptations are documented in Part 6; they are not canon decisions.
3. Work on a branch, never directly on `main`. Keep commits focused.
4. Do not invent lore, rename characters or silently change story beats. Ask when code and bible disagree.
5. Be honest about verification. Static inspection, headless tests, screenshots and an interactive Godot playtest are different levels of evidence.
6. Ask before major restructuring, new systems or control remapping.

### Hard rules from the user

- **Sign dialogue behaviour is intentional:** E opens a sign and walking away closes it. Preserve this.
- **No buffs.** Region mechanics impose debuffs when Lumi ignores the lesson. Do not add stat-boost pickups.
- Keep the tone gentle: quiet over loud, sad rather than edgy. Lust is about longing and obsession, never sexual content.
- Keep code readable and reasonably short; wrap long lines.
- All on-screen text needs a dark outline (`font_outline_color` around `(0.12, 0.10, 0.24)`). Minimum sizes: HUD 17+, world labels 17, dialogue 24, prompts 23. Muted menu text must remain readable.
- Maintain at least 3:1 contrast for solid scene elements. Ground should be the darkest element; characters need a dark outline or light rim. Update `scripts/palette.gd` when adding a region palette.

## Current implementation

<small>Updated 2026-10-31. "Implemented" means present in source, not necessarily validated in an interactive playthrough.</small>

| Area | Current state |
|---|---|
| The Wake | Tutorial path, four signs, Little Jelly, Old Moss, Wind Ribbon, dash gap |
| The Still Pond | Seven-door hub, bench, altar, Memory Tree, Mirror Gate placeholder, Marl, Orrin, Nim |
| Greed — The Gilded Garden | Main route and optional routes, Weight, shrines, enemies, Coin Guard, Collector, two-seal gate, vault exit |
| Sloth — Slumber Hollow | Drowse, lanterns, benches, platforming, enemies, Dozy Warden, Dreamer, two-seal gate, Dream Exit |
| Gluttony — The Endless Table | Fullness/Stuffed, food, enemies, Pantry Loft, Syrup Cellar, Cutlery Knight, Host, two-seal gate, Table Exit |
| Regions 4–7 | Not implemented |
| Mirror Gate and endings | Not implemented |

### Region details

**The Wake**
- Lumi movement, jump, dash, lantern combat, health and healing.
- Four tutorial signs; E opens dialogue and walking away closes it.
- Little Jelly tutorial enemy and Old Moss boss with telegraphed attacks.
- Wind Ribbon unlocks dash and establishes the Wake checkpoint.
- Four room camera layout, visible boundaries and pit recovery.

**The Still Pond**
- Multi-tier hub with seven doors, a bench, Altar of Hands, Memory Tree, Nim's Lantern Post and a Mirror Gate placeholder.
- Marl and Orrin are present.
- The Reflection is a silent visual presence; do not explain or name it in prototype dialogue.
- Region doors unlock as bosses are cleared. Current playable progression reaches Gluttony.

**Greed — The Gilded Garden**
- Carried gold adds Weight; shrines and offering bowls let Lumi give gold away.
- Enemies include Greedy Mites, Penny Pips and Gilded Blossoms.
- Optional routes include the canopy ascent/Gold Ridge and the buried vault.
- Coin Guard is the vault mini-boss; it drops a physical Vault Seal.
- The Collector has three phases: Coin Rain/slam, Feast/growth and Hunger/purse grab. Offering bowls can damage and shrink him.
- Two seals open the Collector approach. The Open Hand manual is in the vault; the Featherweight Charm grants double jump. Defeating the Collector clears Greed and grants the Gold Key.

**Sloth — Slumber Hollow**
- Drowse builds while Lumi is idle or ignores nearby unlit lanterns. Lighting lanterns reduces it.
- Three enemy types, hammock benches, bobbing pillow platforms, loft and sky routes.
- Dozy Warden is the sky-route mini-boss; the second seal is on the loft route.
- Two seals open The Dreamer's arena. The Dreamer has Lullaby, Pillow Fall and Covers Over phases; phase 3 uses climbable walls and a moving lantern-heart.
- Rewards: Hourglass Shard (Tempo Style), Snail Grips (wall climb) and Dusk Key. The Dream Exit returns to the hub.

**Gluttony — The Endless Table**
- Food heals and adds Fullness; at 100, Lumi becomes Stuffed for a limited time. Movement reduces Fullness; mindful eating while badly hurt avoids adding it.
- Enemies: Crumb Swarm, Jelly Gulper and Cutlery Sprite.
- Optional Pantry Loft route contains one seal. Syrup Cellar contains Cutlery Knight, which drops the other seal.
- Two seals open The Host's three-phase fight. Phase 3 uses sweeping jaw walls and a gaping damage window.
- Rewards: Hollow Spoon (Devour Style), Hungry Wind Scarf (Super Dash) and Honey Key. The Table Exit is on the pantry shelf.

### Fighting styles

Tab cycles through unlocked styles. The prototype currently wires four styles:

| Style | Unlock | Implemented moves | Known gaps |
|---|---|---|---|
| Lantern Swing | Starting style | J combo, directional up/pogo, K heavy, L Lantern Flash, I guard, O Warm Light | Dash attack through small enemies is missing; tuning/playtest needed |
| Open Hand (Offering) | Greed vault manual | Palm combo, Offer, Wide Offering, Falling Petals, Gentle Rush, Coin Toss, Open Palm guard, Everything Given | Sticky-coin cleanup, Collector coin return with guard and Altar loadout are incomplete |
| Tempo | Hourglass Shard | Tick-Tock combo, Hour Strike, Pendulum Drop prototype, beat bonus, guard/counter, Stopwatch | Skip, second Pendulum hit, boss slow, Overture; timing/feel need playtesting |
| Devour | Hollow Spoon | Scoop, Gulp, Spit, Open Wide projectile absorption, Taste/Pips (a fourth Pip briefly prevents all actions, even across style swaps) | Slurp Drop, Chomp Dash and Overture |

Move values and prototype differences are recorded in `docs/game-bible.md` Part 6 and the style scripts. Do not treat guessed prototype values as final balance.

### Shared systems

- Gentle / Normal / Hard difficulty and a Gentle Mode setting.
- Weight, Drowse and Fullness debuffs.
- Bench-only saves, Continue and Return to Title.
- Checkpoint-aware death respawn.
- Glow meter and five-petal HUD indicator.
- Title, pause, settings and controls menus.
- Hit-stop and camera shake through a dedicated feedback node.
- Story beats are in `scripts/story.gd` and region boss scripts.

## Controls (prototype)

| Key | Action |
|---|---|
| A / D | Move |
| W / S | Aim up / down; combine with A / D for 8-way aim |
| Space | Jump / double jump when unlocked |
| Left Shift | Dash (super dash after Gluttony reward) |
| J | Attack; W + J aims up; S + J in air performs a downward pogo |
| K | Heavy move (hold/release behaviour depends on equipped style) |
| L | Style skill |
| I | Guard / Open Wide |
| O | Style Overture slot (not implemented for every style) |
| Q | Heal |
| E | Interact |
| Tab | Cycle unlocked fighting styles |
| Esc | Pause / back |

The bible's original control proposal differs. Tab is the user's chosen style-cycle key so Q remains Heal. Do not remap without asking.

## Verification and known limitations

- The repository's latest notes report headless checks and rendered screenshots for parts of Greed, Sloth and Gluttony. These are not equivalent to playing the game in the Godot editor.
- The latest Gluttony notes report the Host phases were exercised through direct damage in a headless test; that does not verify normal combat timing or feel.
- Devour and Tempo have partial headless checks. Gulp, Open Wide, Tempo move feel and normal editor playtesting remain unverified.
- The latest documented project feature tag is Godot 4.7. Use Godot 4.7 or newer unless the tag is deliberately changed and compatibility is tested.
- The audit branch includes static code fixes for duplicate Devour hits and Tempo's Stopwatch target handling. Those changes have **not** been run in Godot during this audit.

### Outstanding work

1. Run the full Wake → Hub → Greed → Sloth → Gluttony progression in Godot.
2. Playtest each seal gate in both collection orders, each mini-boss, all boss phases and all region exits.
3. Validate all four fighting styles, style switching, guards, Glow costs and save/load unlock restoration.
4. Complete missing Tempo and Devour moves; resolve prototype/bible differences deliberately.
5. Implement Envy, Lust, Wrath, Pride, Mirror Gate, endings, side quests and remaining gadgets/styles.
6. Add final art, animation, music and sound; finish the map/loadout/Memory Tree/keepsake screens and key remapping/audio options.
7. Revisit balance values that are explicitly marked as guesses.

## Tech and running the project

- Godot 4.7+ / GDScript
- GL Compatibility renderer
- 1280 × 720 project viewport
- Current visuals are largely drawn with `_draw()` and runtime-created nodes; imported art/audio is not yet integrated.
- Windows and Linux targets.

Open `project.godot` in Godot Project Manager and press F5.

## Important files

| Path | Purpose |
|---|---|
| `project.godot` | Engine settings and input map |
| `scenes/main.tscn` | Main scene entry point |
| `scripts/main.gd` | Wake, transitions, save orchestration and camera |
| `scripts/player.gd` | Lumi movement, health, base combat and style ownership |
| `scripts/hub.gd` | The Still Pond and region doors |
| `scripts/greed.gd`, `scripts/collector.gd` | Greed region and The Collector |
| `scripts/sloth.gd`, `scripts/dreamer.gd` | Sloth region and The Dreamer |
| `scripts/gluttony.gd`, `scripts/host.gd` | Gluttony region and The Host |
| `scripts/open_hand.gd` | Open Hand style |
| `scripts/tempo_style.gd` | Tempo style |
| `scripts/devour_style.gd` | Devour style |
| `scripts/lantern_kit.gd` | Lantern Swing's extra moves |
| `scripts/save_game.gd`, `scripts/run_state.gd` | Save data and difficulty scaling |
| `scripts/palette.gd` | Shared palette and contrast rules |
| `docs/game-bible.md` | Canonical design reference and prototype notes |
| `IMPLEMENTATION_STATUS.md` | Detailed implementation and verification status |
| `CHECKLIST.md` | Remaining implementation and playtest tasks |

## Design pillars

- Every sin is a good thing taken too far; every boss is still someone kind.
- The world teaches through mechanics, not lectures.
- No buffs: lessons remove harmful debuffs rather than granting power-ups.
- The Reflection is discovered gradually. Do not spoil it in dialogue.
- The intended final victory is acceptance, not defeating the self.
