# Gielinor Survivors — Architecture

## Runtime boundaries

The game is split into four layers. Systems should communicate through typed signals or narrow public methods rather than reaching into unrelated nodes.

### 1. Presentation

Responsible for rendering and player feedback only:

- `PlayerController`: reads input and moves the character.
- `OrbitCamera`: follows and orbits the player.
- `GameHUD`: presents run state, skill panels, hitsplats and combat log.
- Character/enemy scenes: visual rigs, animation and audio emitters.

Presentation nodes should not decide drop rates, calculate weapon damage or award permanent XP.

### 2. Run systems

Created for a single run and discarded when that run ends:

- `RunDirector`: owns run phase and coordinates start, active play, death and results.
- `WaveDirector`: chooses the current wave and schedules spawn groups.
- `SpawnDirector`: turns spawn requests into enemy instances, with caps and pooling hooks.
- `CombatDirector`: resolves attack requests, hit checks and damage events.
- `TargetSelector`: finds eligible targets using a configurable policy.
- `DropDirector`: rolls drops and creates world pickups.
- `RunInventory`: holds gathered materials and temporary equipment.
- `SlayerContract`: tracks task progress and rewards.
- `CraftingDirector`: validates recipes and applies equipment upgrades.
- `RunSkillState`: owns temporary skill XP, level choices, active prayers and run-only unlocks.

### 3. Persistent profile

Survives between runs and is loaded at boot:

- `ProfileService`: loads, validates, migrates and saves the profile.
- `MetaProgression`: converts run results into permanent skill XP and unlocks.
- `UnlockCatalog`: defines permanent unlocks and prerequisites.
- `SettingsService`: stores input, audio and display settings.

A run must not directly edit persistent profile files. At death or extraction, it produces a `RunResult`; the meta-progression service applies that result and then the profile service saves it.

### 4. Data definitions

Balance data lives in custom Godot `Resource` assets (`.tres`) rather than manager code. Scenes contain presentation and composition; resources contain tunable values and IDs.

Planned resource types:

| Resource | Key fields |
|---|---|
| `WeaponData` | stable ID, display name, attack style, range, cadence, target policy, damage, projectile scene, special definition |
| `MonsterData` | stable ID, display name, max HP, movement speed, contact damage, XP value, tags, drop table, scene |
| `SkillDefinition` | stable ID, skill name, XP curve, unlock tiers, icon and description |
| `UpgradeDefinition` | stable ID, eligible skills, prerequisites, rarity, effects and level cap |
| `WaveDefinition` | spawn groups, threat budget, intermission duration, boss rules |
| `SlayerTaskDefinition` | eligible monster tags, target count range, reward table and difficulty band |
| `RecipeDefinition` | station type, input quantities, skill requirement, output item and upgrade effect |
| `DropTable` | weighted entries, quantity ranges, rarity modifiers |

Use stable string IDs in save data. Never save a node path, scene-tree path or array index as the permanent identity of an unlock or item.

## Combat event flow

1. The equipped weapon requests an attack when its cooldown is ready.
2. `TargetSelector` finds a live, valid target within the weapon's range and line-of-sight rules.
3. The weapon execution strategy resolves melee, projectile or spell delivery.
4. `CombatDirector` applies hit chance, damage modifiers, defence, Prayer effects and special-attack modifiers in a defined order.
5. The target emits a `damaged` event; presentation displays the hitsplat and combat-log entry.
6. On death, the enemy emits one death event. XP, drops, Slayer progress, kill counters and special-energy gain subscribe to that event.

The enemy must have a single authoritative death transition so damage-over-time, projectiles and simultaneous hits cannot award duplicate XP or drops.

## Run-state lifecycle

`HUB -> STARTING -> ACTIVE <-> INTERMISSION -> BOSS -> ACTIVE -> PLAYER_DEFEATED -> RESULTS -> HUB`

The run director is the only owner of this state. Systems can request transitions (for example, the wave director requests an intermission), but the run director validates and applies them.

## Progression separation

There are two intentionally separate progress tracks:

- **Run skills:** temporary XP and level choices reset when the run ends. These directly affect the current character's combat and survival capabilities.
- **Permanent skills:** persistent XP earned from the run result. These unlock starting bonuses, crafting tiers, skill-specific options and new content. They do not silently overwrite current-run choices.

Prayer uses a separate prayer-point pool. Active prayers are explicit toggles with drain rates and mutually-exclusive groups. Rare drops and shrines restore points; prayer should not be implemented as a free permanent stat bonus.

## Performance strategy

Start with straightforward nodes and profile before optimizing. When enemy counts justify it:

- pool frequently spawned enemies, projectiles, XP drops and hitsplat effects;
- stagger enemy target updates instead of recalculating every enemy every frame;
- use squared distance checks for target filtering;
- keep physics collision layers narrow;
- use MultiMesh for purely decorative repeated scenery, not independently interactive enemies;
- centralize spawn caps and projectile caps in run configuration.

## Save format

Use a versioned JSON profile for the first persistent implementation:

```json
{
  "schema_version": 1,
  "profile_id": "local-profile",
  "permanent_skill_xp": {},
  "unlocks": [],
  "settings": {}
}
```

Saving should be atomic: write a temporary file, validate it, then replace the previous profile. On load, migrate older schema versions before exposing the profile to gameplay. Keep a backup before applying a migration.

## Phase gates

### Phase 1 — controller and camera

- Player moves in camera-relative directions.
- Sprint is optional and independent of camera yaw.
- Middle-mouse drag orbits horizontally and vertically.
- Wheel zoom is clamped; the SpringArm prevents camera clipping.
- Player remains grounded on the test floor.

### Phase 2 — combat and special attacks

- Weapon data drives cadence, range, style and attack delivery.
- Target selection is deterministic and configurable.
- Auto-attacks stop cleanly when no target is valid.
- Damage and death events are authoritative and cannot double-award rewards.
- Special energy is bounded from 0 to 100 and weapon specials spend it once.

### Phase 3 — waves and Slayer

- Wave definitions can be added without editing the wave director.
- Spawn budgets and enemy caps prevent uncontrolled growth.
- Slayer task progress is based on monster tags and the authoritative death event.
- Boss waves have explicit telegraphs and recovery windows.

### Phase 4 — skills, drops and crafting

- Skill curves and upgrade effects are data-driven.
- XP drops are pooled and can be magnetized/collected reliably.
- Crafting validates materials, station, skill and recipe before consuming anything.
- Prayer drain and restoration are testable independently.

### Phase 5 — results, UI and meta-progression

- Death produces a complete `RunResult` exactly once.
- Permanent XP calculation is deterministic and inspectable.
- Save/load survives restarts and schema migration.
- UI is a presentation layer over run/profile state, not the source of truth.


## Phase 2 implementation — first combat loop

The current playable slice adds the first version of the run systems while preserving the Phase 1 controller and orbit camera.

- `WeaponData` is a Resource asset. The Bronze Sword definition supplies attack style, damage, cadence, range, target policy and special-attack tuning.
- `AutoCombat` owns attack cadence, target selection, special energy and the Q special input. It subscribes to enemy death signals to award special energy.
- `EnemyController` provides reusable chasing, contact attacks, wave-scaled Hitpoints and a single authoritative death signal.
- `WaveManager` owns the preparation, spawning, clearing, intermission and defeated states. It limits simultaneously active enemies and scales goblin health, speed and damage by wave.
- `PlayerController` owns player Hitpoints and emits one death transition. The HUD reads state from these gameplay systems and does not own it.
- The Goblin scene is a low-poly placeholder and should be replaced by a rigged monster scene without changing the wave or combat APIs.

### Combat event flow

1. AutoCombat selects an eligible enemy within the weapon range using the configured target policy.
2. WeaponData supplies the damage and cadence; EnemyController receives one damage call.
3. EnemyController creates a floating damage number and, at zero Hitpoints, emits one death signal before freeing itself.
4. WaveManager reduces its active count. AutoCombat awards special energy. Both listen to the same authoritative death event.
5. At 50 special energy, Q activates the Bronze Sword's Whirlwind and damages eligible enemies within its area radius.

### Current prototype limits

The current Bronze Sword is a melee-only starter weapon. There are no ranged projectiles, magic autocasts, equipment inventory, Slayer contracts, XP drops, boss phases or persistent run profile yet. Those remain the next additions rather than being represented by non-functional UI placeholders.
