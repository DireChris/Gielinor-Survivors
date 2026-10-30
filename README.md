# Gielinor Survivors

A 3D wave-survival rogue-lite inspired by the atmosphere, monsters, equipment and progression of Old School RuneScape.

> **Current status:** Phase 2 combat prototype — a RuneLite-inspired free-orbit camera, player movement and a first playable loop with goblin waves, automatic melee attacks, hitsplats, Hitpoints and a special attack.

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

Push a version tag such as `v0.2.0` to create a GitHub Release automatically. The release attaches `gielinor-survivors-windows.zip` directly.

## Open the project in Godot

1. Install Godot **4.7.2 stable** from https://godotengine.org/download/.
2. Start Godot and choose **Import**.
3. Select this repository's `project.godot` file.
4. Open the project and press **F5** to run it.

The project is designed for desktop keyboard and mouse.

## Controls

| Input | Action |
|---|---|
| W / A / S / D | Move relative to camera direction |
| Arrow keys | Alternative movement |
| Left Shift | Sprint |
| Hold middle mouse + drag | Orbit camera (yaw and pitch) |
| Mouse wheel | Zoom in / out |
| Q | Special attack (when special energy is available) |

The player automatically attacks nearby enemies using the equipped weapon. The first weapon is a Bronze Sword with a Whirlwind area special.

## Current combat loop

- The first wave begins after a short preparation countdown.
- Goblins spawn around the arena and chase the player.
- The Bronze Sword automatically attacks the nearest goblin in melee range.
- Damage numbers appear above enemies; defeated enemies charge special energy.
- Press **Q** with at least 50% special energy to use Whirlwind against nearby enemies.
- Goblin health, movement speed and contact damage scale as waves progress.
- Player Hitpoints are shown in the HUD. Reaching zero ends the run.

## Build locally

Install Godot 4.7.2 and its export templates, then run from the repository root:

```powershell
New-Item -ItemType Directory -Force build
godot --headless --editor --path . --quit
godot --headless --path . --export-release "Windows Desktop" "build/gielinor-survivors.exe"
Compress-Archive -Path "build/*" -DestinationPath "gielinor-survivors-windows.zip" -CompressionLevel Optimal -Force
```

The export preset writes `build/gielinor-survivors.exe`; Godot creates the matching `build/gielinor-survivors.pck`.

## Project structure

```text
res://
├── .github/workflows/
│   └── build.yml
├── assets/
│   ├── audio/
│   ├── materials/
│   └── models/
├── data/
│   ├── monsters/
│   ├── skills/
│   └── weapons/
│       └── bronze_sword.tres
├── scenes/
│   ├── enemies/
│   │   └── goblin.tscn
│   ├── player/
│   └── main.tscn
├── scripts/
│   ├── combat/
│   │   ├── auto_combat.gd
│   │   └── weapon_data.gd
│   ├── enemies/
│   │   └── enemy_controller.gd
│   ├── player/
│   │   ├── orbit_camera.gd
│   │   └── player_controller.gd
│   ├── ui/
│   │   └── game_hud.gd
│   └── waves/
│       └── wave_manager.gd
├── export_presets.cfg
└── project.godot
```

## Planned phases

1. **Player controller and camera** — movement, orbit, zoom and ground collision. *(Complete foundation.)*
2. **Combat and special attacks** — target selection, data-driven weapon definitions, automatic melee attacks, hitsplats, Hitpoints, special energy and the first area special. *(Current prototype.)*
3. **Waves and Slayer tasks** — wave scaling is in place; next comes Slayer contracts, monster variety, bosses and task rewards.
4. **Skills, drops and crafting** — XP orbs, skill choices, Prayer, gathering nodes, crafting stations and equipment progression.
5. **Death, UI and meta-progression** — run summary, persistent skill XP, unlock tree, full OSRS-inspired interface and audio.

## Architecture direction

See [ARCHITECTURE.md](ARCHITECTURE.md) for subsystem ownership, event flow, save format, performance strategy and phase acceptance criteria. Weapon, monster, skill, drop-table and wave definitions are being separated from runtime managers. Godot custom `Resource` assets (`.tres`) are the preferred format for tunable gameplay data. Save data will be versioned before permanent progression is introduced.

## Asset and IP note

This project is an unofficial fan-inspired game. Use original work, assets you have permission to use, or assets under compatible licences. Do not distribute proprietary game files, extracted OSRS models/textures, or copyrighted soundtrack files as part of the project.
