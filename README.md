# Gielinor Survivors

A 3D wave-survival rogue-lite inspired by the atmosphere, monsters, equipment and progression of Old School RuneScape.

> **Current status:** Early playable prototype — third-person orbit camera, movement, automatic melee combat, goblin waves, special attacks, Slayer contracts, skill XP, loot, crafting and a first persistent profile.

## Engine

- **Godot 4.7.2 stable**
- GDScript (no .NET runtime required)
- GL Compatibility renderer
- Procedural articulated low-poly character rigs with AnimationPlayer states; no external assets required

## Get a playable Windows build

Every push to `main` and pull request targeting `main` runs the Windows export workflow.

1. Open the repository's **Actions** tab.
2. Select the latest successful **Windows Build** run.
3. Download the `gielinor-survivors-windows` artifact.
4. Extract the downloaded artifact ZIP once. It contains only `gielinor-survivors.exe` and its matching `gielinor-survivors.pck` at the top level.
5. Run `gielinor-survivors.exe`; keep the PCK in the same folder.

The workflow checks project-import and main-scene logs for script/resource errors, exports the Windows Desktop preset, verifies the EXE and PCK, and creates a clean release ZIP with those two files at its root. The Actions artifact uploads the files directly, avoiding a ZIP nested inside GitHub's artifact ZIP.

Push a version tag such as `v0.3.0` to create a GitHub Release automatically. The release attaches `gielinor-survivors-windows.zip` directly.

## Open the project in Godot

1. Install Godot **4.7.2 stable** from https://godotengine.org/download/.
2. Start Godot and choose **Import**.
3. Select this repository's `project.godot` file.
4. Open the project and press **F5** to run it.

## Controls

| Input | Action |
|---|---|
| W / A / S / D | Move relative to camera direction |
| Arrow keys | Alternative movement |
| Left Shift | Sprint |
| Hold middle mouse + drag | Orbit camera |
| Mouse wheel | Zoom |
| Q | Weapon special attack |
| C | Craft the Bronze Edge upgrade when materials are available |

## Current playable systems

- Goblins spawn in escalating waves and pursue the player. Both player and goblin use articulated low-poly rigs with idle, run, attack and death animations; the player also has a special-attack animation.
- The Bronze Sword automatically attacks nearby enemies; Q triggers Whirlwind when enough special energy is available.
- Automatic attacks face the selected target and emit a directional slash; Q Whirlwind performs a forward-facing 150-degree sweep. Damage numbers appear above enemies.
- The Goblin Clearance Slayer contract is defined as a data resource and tracks 15 goblin kills, awarding bonus Slayer XP and coins.
- Goblin loot is rolled from a data-driven drop table; an InventoryService handles item counts and atomic crafting costs.
- Attack, Strength, Defence, Hitpoints and Slayer gain run XP from kills. OSRS-style level thresholds are used.
- Every skill level-up pauses the run and offers up to three choices: Keen Edge (damage), Swift Strikes (attack speed), Fleetfoot (movement), Vitality (maximum Hitpoints and healing), Focused Spirit (special energy) or Long Reach (attack range). Upgrade ranks are run-only and reset on a new run.
- Goblins can drop coins, copper ore and bones.
- Crafting the Bronze Edge costs 5 copper ore, 3 bones and 30 coins; it adds weapon damage for the current profile.
- On player defeat, run skill XP is banked into a versioned local profile at `user://gielinor_survivors_profile.json`. Permanent XP, lifetime kills and the crafted weapon unlock persist between launches.

## Important prototype limits

This is a systems foundation, not a finished game. The current characters are procedural articulated low-poly rigs rather than imported, skinned OSRS-style models; the rigs use AnimationPlayer states rather than final AnimationTrees; custom model assets, ranged weapons, magic autocasts, full equipment/inventory interface, multiple Slayer task types, boss encounters, Prayer system, gathering stations, recipe catalogue and complete meta-progression tree are still future work. The first craft is a single starter upgrade, and the current profile stores progression rather than a full run save.

## Build locally

Install Godot 4.7.2 and its export templates, then run from the repository root:

```powershell
New-Item -ItemType Directory -Force build
godot --headless --editor --path . --quit
godot --headless --path . --export-release "Windows Desktop" "build/gielinor-survivors.exe"
Compress-Archive -Path "build/*" -DestinationPath "gielinor-survivors-windows.zip" -CompressionLevel Optimal -Force
```

## Project structure

```text
res://
├── .github/workflows/build.yml
├── assets/ (currently reserved for future licensed models, materials and audio)
├── data/weapons/bronze_sword.tres
├── data/upgrades/
├── data/drops/goblin_drop_table.tres
├── data/slayer/goblin_clearance.tres
├── scenes/
│   ├── enemies/goblin.tscn
│   └── main.tscn
└── scripts/
    ├── combat/
    ├── enemies/
    ├── player/
    ├── progression/
    ├── visuals/character_rig.gd
    ├── ui/
    └── waves/
```

## Architecture

Gameplay ownership is split between presentation, run systems, item storage, Slayer contracts, monster drop data, persistent profile and data definitions. ProgressionDirector coordinates these systems without owning their inventories, drop rolls or contract counters. See [ARCHITECTURE.md](ARCHITECTURE.md).

## Asset and IP note

This project is an unofficial fan-inspired game. Use original work, assets you have permission to use, or assets under compatible licences. Do not distribute proprietary game files, extracted OSRS models/textures, or copyrighted soundtrack files as part of the project.
