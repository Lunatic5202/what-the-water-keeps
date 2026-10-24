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

## Current status: Prototype 02 (Wake → Still Pond → Greed)

Implemented in code:
- Lumi movement, jump, dash, lantern swing, health and healing
- Four Wake tutorial signs and the Little Jelly
- Old Moss tutorial boss; the Wind Ribbon appears after his defeat
- Wind Ribbon unlocks dash and sets the Wake checkpoint
- A post-boss gap intended to require jump + dash before the first door
- The Still Pond hub with seven doors, bench, altar, Memory Tree, Mirror Gate placeholder, Marl and Orrin
- Greed region with coins, weight penalties, offering shrines, lore tablets and a Featherweight Charm pickup that unlocks double jump
- Wake → Hub → Greed → Hub handoff using the same Lumi instance
- Pit recovery, checkpoint-aware death respawn, visible Wake boundaries, hit-stop and camera-shake feedback

Still incomplete:
- The Collector boss fight and actual Greed clear/reward progression
- Other region implementations, full fighting styles, memory petals, saves, menus, music and imported art
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
| `docs/game-bible.md` | Full design reference (story, regions, bosses, movesets, art, sound, UI) |

## Controls (prototype)

| Key | Action |
|-----|--------|
| A / D | Move |
| Space | Jump |
| Left Shift | Dash |
| J | Lantern swing |
| Q | Heal |
| E | Interact |

The bible's final control scheme differs (heal on H, Q cycles fighting styles, plus heavy attack, guard and more). Ask before remapping.

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

## How the code works

- `main.gd` keeps a list of `interactables` (dictionaries with `node`, `message`, `kind`, `used`). `_process` finds the nearest one within 95px, shows the E prompt and handles opening and closing dialogue.
- New interactables go through `_make_marker()` and `interactables.append(...)`.
- Status messages go through `_show_status()`. Only the newest message restores the HUD.
- `player.gd` emits `health_changed`, `heals_changed` and `status_changed`. `main.gd` listens and updates the HUD.
- Enemies join the damage system by having a `take_damage(amount)` method. The player's attack area calls it.

## Roadmap (suggested order)

1. Playtest and stabilize Wake → Still Pond → Greed → Still Pond.
2. Implement The Collector boss fight and the actual Greed clear/reward condition.
3. Connect region-clear rewards to hub door unlocks and gadget progression.
4. Build the remaining six regions and their bosses, keeping the game bible as the source of truth.
5. Add the Mirror Gate, Memory Path, final fight and both endings.
6. Add saves, side quests, Memory Petals, then polish art, music and sound.

## Design pillars (short version)

- Every mechanic is also a moral lesson. Ignore it and the world answers back.
- Each artifact is the virtue that answers its sin, and unlocks a distinct fighting style.
- Cute on the surface. Small uncanny details grow as the game goes on.
- The final fight is unwinnable by fighting. Standing still for about 8 seconds lets the player accept themselves (good ending). Striking during the 5 to 6 second cutscene window leads to the bad ending.

## Testing notes for agents

- Godot is often not installed in agent sandboxes. If it is not, say so, and do a syntax check instead, for example `pip install gdtoolkit` then `gdparse scripts/*.gd`.
- Ask the user to playtest and report exact errors or feel problems.
- Known rough spots: the dash gap width is tight and may need tuning.
- Runtime testing is still required after the progression and transition changes.
