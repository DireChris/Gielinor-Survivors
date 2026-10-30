# Gielinor Survivors

A 3D wave-survival rogue-lite inspired by the atmosphere, monsters, equipment and progression of Old School RuneScape.

> **Current status:** Phase 1 foundation — third-person movement, a RuneLite-inspired free-orbit camera and a lightweight prototype HUD. Combat, waves and progression are planned next.

## Engine

- **Godot 4.7.2 stable**
- GDScript (no .NET runtime required)
- GL Compatibility renderer
- Procedural placeholder geometry; no external assets required

## Get a playable Windows build

Every push to `main` and pull request targeting `main` runs the Windows export workflow.

1. Open the repository's **Actions** tab.
2. Select the latest successful **Windows Build** run.
3. Download the `Gielinor-Survivors-Windows` artifact.
4. Extract the downloaded artifact ZIP.
5. Keep `Gielinor Survivors.exe` and `Gielinor Survivors.pck` together in the same folder, then run the EXE.

The PCK contains the game data required by the executable. Both files are included in the artifact and in tagged GitHub Releases. A single-file embedded PCK is deliberately not used because it can increase antivirus false positives for unsigned Windows executables.

Push a version tag such as `v0.1.0` to create a GitHub Release automatically. The release will include the Windows EXE and its matching PCK.

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
| Escape | Release the mouse cursor while orbiting |

The camera follows the player, collides with the environment through a SpringArm3D, and clamps its pitch to prevent flipping.

## Build locally

Install Godot 4.7.2 and its export templates, then run from the repository root:

```powershell
New-Item -ItemType Directory -Force build
godot --headless --editor --path . --quit
godot --headless --path . --export-release "Windows Desktop" "build/Gielinor Survivors.exe"
```

The export creates `Gielinor Survivors.exe` and `Gielinor Survivors.pck` in the build folder.

## Project structure

```text
res://
├── .github/workflows/
│   └── windows-build.yml
├── assets/
│   ├── audio/
│   ├── materials/
│   └── models/
├── data/
│   ├── monsters/
│   ├── skills/
│   └── weapons/
├── scenes/
│   ├── player/
│   └── main.tscn
├── scripts/
│   ├── player/
│   │   ├── orbit_camera.gd
│   │   └── player_controller.gd
│   └── ui/
│       └── game_hud.gd
├── export_presets.cfg
└── project.godot
```

The empty `assets/` and `data/` directories are intentional extension points for original/licensed art, audio and data resources.

## Planned phases

1. **Player controller and camera** — movement, orbit, zoom and ground collision. *(Current foundation.)*
2. **Combat and special attacks** — target selection, weapon definitions, auto-attacks, hitsplats and special energy.
3. **Waves and Slayer tasks** — spawn director, enemy profiles, wave scaling, task contracts and boss events.
4. **Skills, drops and crafting** — XP orbs, skill choices, Prayer, gathering nodes, crafting stations and equipment progression.
5. **Death, UI and meta-progression** — run summary, persistent skill XP, unlock tree, full OSRS-inspired interface and audio.

## Architecture direction

See [ARCHITECTURE.md](ARCHITECTURE.md) for subsystem ownership, event flow, save format, performance strategy and phase acceptance criteria. Gameplay definitions will be data-driven rather than hard-coded into managers. Godot custom `Resource` assets (`.tres`) are the preferred format for weapon, monster, skill, drop-table and wave definitions. Runtime systems will consume those resources through small, focused managers. Save data will be versioned so the format can evolve without discarding player progression.

## Asset and IP note

This project is an unofficial fan-inspired game. Use original work, assets you have permission to use, or assets under compatible licences. Do not distribute proprietary game files, extracted OSRS models/textures, or copyrighted soundtrack files as part of the project.
