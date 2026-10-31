# Agent instructions

This is a Godot 4 game, "What the Water Keeps".

Before doing anything:

1. Read `README.md` for project rules, current region/style status, controls and architecture.
2. Read `docs/game-bible.md` for canon, story, regions, bosses and tone.
3. Read `IMPLEMENTATION_STATUS.md` for source status and verification evidence.
4. Read `CHECKLIST.md` before planning implementation or playtesting.

Key rules:

- Work on a branch, never on `main`. Keep commits focused.
- Do not change sign dialogue behaviour: E opens; walking away closes. This is intentional.
- No buffs in this game, only debuffs.
- Do not invent lore. Follow the bible, or ask.
- The game bible is canon. Part 6 records prototype deviations, not canon decisions.
- Distinguish source implementation, static inspection, headless tests, screenshots and interactive Godot playtests. Never claim a test was run if it was not.
- Preserve the gentle tone, readable text outlines and minimum contrast rules in the README.
- Ask before major restructuring or control remapping.
