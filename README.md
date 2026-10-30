# Gielinor Survivors

A 3D wave-survival rogue-lite inspired by the atmosphere, monsters, equipment and progression of Old School RuneScape.

> **Current status:** Early playable prototype — third-person orbit camera, movement, automatic melee combat, goblin waves, special attacks, Slayer contracts, skill XP, loot, crafting and a first persistent profile.

## Engine

- **Godot 4.7.2 stable**
- GDScript (no .NET runtime required)
- GL Compatibility renderer
- Procedural low-poly placeholder geometry; no external assets required

## Get a playable Windows build

Every push to `main` and pull request targeting `main` runs the Windows export workflow.

1. Open the repository's **Actions** tab.
2. Select the latest successful **Windows Build** run.
3. Download the `gielinor-survivors-windows` artifact.
4. Extract the downloaded GitHub artifact ZIP, then extract `gielinor-survivors-windows.zip`.
5. Run `gielinor-survivors.exe`. Keep the matching `gielinor-survivors.pck` beside it.

The workflow validates the Godot project headlessly, exports the Windows Desktop preset, verifies both exported files, creates a ZIP from the build folder and checks that the ZIP contains the EXE and PCK before uploading it.

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

- Goblins spawn in escalating waves and pursue the player.
- The Bronze Sword automatically attacks nearby enemies; Q triggers Whirlwind when enough special energy is available.
- Weapon hits and specials create expanding impact rings; damage numbers appear above enemies.
- A Slayer contract tracks 15 goblin kills and awards bonus Slayer XP and coins.
- Attack, Strength, Defence, Hitpoints and Slayer gain run XP from kills. OSRS-style level thresholds are used.
- Goblins can drop coins, copper ore and bones.
- Crafting the Bronze Edge costs 5 copper ore, 3 bones and 30 coins; it adds weapon damage for the current profile.
- On player defeat, run skill XP is banked into a versioned local profile at `user://gielinor_survivors_profile.json`. Permanent XP, lifetime kills and the crafted weapon unlock persist between launches.

## Important prototype limits

This is a systems foundation, not a finished game. The character and goblin are still placeholder geometry; there are no rigged attack animations, ranged weapons, magic autocasts, full equipment/inventory interface, multiple Slayer task types, boss encounters, Prayer system, gathering stations, recipe catalogue, upgrade-choice screen or complete meta-progression tree yet. The first craft is a single starter upgrade, and the current profile stores progression rather than a full run save.

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
├── assets/
├── data/weapons/bronze_sword.tres
├── scenes/
│   ├── enemies/goblin.tscn
│   └── main.tscn
└── scripts/
    ├── combat/
    ├── enemies/
    ├── player/
    ├── progression/progression_director.gd
    ├── ui/
    └── waves/
```

## Architecture

Gameplay ownership is split between presentation, run systems, persistent profile and data definitions. The progression director currently bridges run XP, Slayer, drops, a starter recipe and profile persistence; future work should split those into dedicated services as their scope grows. See [ARCHITECTURE.md](ARCHITECTURE.md).

## Asset and IP note

This project is an unofficial fan-inspired game. Use original work, assets you have permission to use, or assets under compatible licences. Do not distribute proprietary game files, extracted OSRS models/textures, or copyrighted soundtrack files as part of the project.
