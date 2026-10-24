# Implementation Status

**Last Updated:** 2026-10-24

## ✅ Completed

### Wake Tutorial (Complete)
- ✅ Movement, jump, dash mechanics
- ✅ Tutorial signs with E-to-read interaction
- ✅ Little Jelly enemy (patrol, contact damage, knockback)
- ✅ **Old Moss boss** (head bump, roll, spore attacks)
- ✅ Wind Ribbon pickup (unlocks dash)
- ✅ Checkpoint system and pit respawn
- ✅ Level boundaries with visible stone posts
- ✅ Camera limits
- ✅ Greed door transition prompt

### Player Systems (Complete)
- ✅ Health (5 hearts) and heal charges (2)
- ✅ Lantern swing attack with damage system
- ✅ Dash with cooldown
- ✅ Double jump support (unlocked via Wind Ribbon)
- ✅ Movement modifiers (speed/jump power for debuffs)
- ✅ Hurt cooldown and death handling
- ✅ Visual feedback (hurt flash, attack arc)

### Hub - The Still Pond (New)
- ✅ Circular hub with The Still Pond at center
- ✅ Seven doors (one per region)
- ✅ Bench of Rest (heal/save)
- ✅ Altar of Hands (style loadout placeholder)
- ✅ Memory Tree (petal collection placeholder)
- ✅ Nim's Lantern Post
- ✅ NPCs: Marl (paper boats), Orrin (stone frog)
- ✅ Mirror Gate (final boss entrance)
- ✅ Reflection that follows player with lag

### Greed Region - The Gilded Garden (New)
- ✅ Golden garden environment
- ✅ Coin pickups (+10 gold each)
- ✅ Weight debuff system (gold slows movement/jump)
- ✅ Shrines (offer gold to reduce weight)
- ✅ Lore tablets (3)
- ✅ Platforming sections
- ✅ The Collector boss area (encounter only, fight not implemented)
- ✅ Exit to hub

### Scripts Created
- `scripts/old_moss.gd` - Tutorial boss
- `scripts/moss_spore.gd` - Spore projectiles
- `scripts/hub.gd` - Hub scene
- `scripts/greed.gd` - Greed region

### Input System
- ✅ All movement controls (A/D, Space, Shift, J, Q, E)
- ✅ **T key** - Enter region transitions

## 🚧 In Progress

### Scene Transitions
- ⚠️ Wake → Hub transition (structure ready, needs testing)
- ⚠️ Hub → Greed transition (structure ready, needs testing)
- ⚠️ Region → Hub return flow

## ❌ Not Implemented

### Wake
- ❌ Old Moss defeat dialogue improvements

### Hub
- ❌ Side quests (Paper Boats, Bench Keeper, Table of Remembering)
- ❌ Door unlocking logic per region clear
- ❌ Hub music detune as regions clear
- ❌ Table of Remembering for boss keepsakes

### Greed - Missing Features
- ❌ The Collector boss fight
- ❌ Featherweight Charm pickup (double jump gadget)
- ❌ The Open Hand artifact (Offering Style)
- ❌ Gold Key reward
- ❌ Enemies: Penny Pips, Magpie Thieves, Chest Mimics, Gilded Blossoms
- ❌ Memory Petals (5 hidden)
- ❌ Side quests: The Last Coin, The Egg That Never Hatched

### All Other Regions
- ❌ Sloth (Slumber Hollow)
- ❌ Gluttony (The Endless Table)
- ❌ Envy (The Gallery of Glass)
- ❌ Lust (The Ribbon Orchard)
- ❌ Wrath (The Ashen Kettle)
- ❌ Pride (The Tower of Applause)
- ❌ Mirror Gate (final boss)

### Combat Systems
- ❌ Fighting styles (7 total)
- ❌ Glow meter
- ❌ Style switching
- ❌ Overtures (finishers)
- ❌ Heavy attacks

### Progression
- ❌ Memory Petals collection
- ❌ Keepsakes system
- ❌ Region keys
- ❌ Save/load system
- ❌ Settings menu

## 🐛 Known Issues

1. **No Godot in environment** - Can't run/test the game directly
2. **Scene transitions untested** - May have bugs with player reparenting
3. **Camera limits** - Need adjustment per region
4. **Weight debuff** - Visual feedback needed
5. **Hub background** - _draw() may not render correctly on first load

## 📝 Next Steps (Priority Order)

1. **Test in Godot** - Load project and verify all scripts compile
2. **Fix scene transitions** - Make Wake → Hub → Greed work smoothly
3. **Build The Collector boss** - Complete Greed region
4. **Add Featherweight Charm** - Double jump gadget unlock
5. **Build remaining 6 regions** - Follow the roadmap

## 🎯 Current Focus

Building out the core game loop:
- Wake tutorial → Hub → First region (Greed) → Boss → Return to Hub

Once this loop works, repeat for 6 more regions.

## 📚 Documentation

- `README.md` - Project overview
- `docs/game-bible.md` - Complete design reference
- `AGENTS.md` - Instructions for AI agents
- `CLAUDE.md` - Brief project pointer
