# Gielinor Survivors — Architecture

## Runtime boundaries

The game is split into four layers. Systems communicate through typed signals or narrow public methods rather than reaching into unrelated nodes.

### Presentation
- `PlayerController`: movement and player Hitpoints.
- `OrbitCamera`: third-person orbit and zoom.
- `GameHUD`: presents run state, skills, Slayer, inventory, upgrades and special energy.
- `LevelUpChoiceUI`: pause-safe choice overlay; it renders offers and forwards the selected stable upgrade ID.
- Character/enemy scenes: visual rigs, animation and audio emitters.

Presentation does not decide drop rates, calculate damage or award permanent XP.

### Run systems
- `WaveManager`: wave spawning, intermission and defeat state.
- `AutoCombat`: weapon cadence, target selection, special energy and directional combat effects. It faces the player towards the selected target before damage is applied; Whirlwind uses a configurable forward arc.
- `ProgressionDirector`: coordinates run XP, death banking and starter weapon unlocks. Emits one level-up event per XP threshold crossed.
- `InventoryService`: owns run item counts and validates multi-item costs atomically before crafting.
- `SlayerContractService`: owns contract progress and emits completion rewards; definitions are `SlayerContractData` resources.
- `DropTableData`: monster-owned resource containing independently rolled `DropEntryData` entries.
- `RunUpgradeDirector`: queues skill level-ups, pauses the tree, offers up to three eligible run upgrades, applies the selected effect and resumes play. Upgrade definitions are Resources; ranks are run-only.
- `EnemyController`: movement, contact attacks, health and one authoritative death signal.

### Persistent profile
The progression director reads and writes a versioned JSON profile under Godot's `user://` directory. Run XP is banked when the player is defeated. The profile stores permanent skill XP, lifetime kills and the Bronze Edge unlock. A future `ProfileService` should own schema migrations, backups and atomic saves independently of run systems.

### Data definitions
Weapon balance is held in `WeaponData` resources. Monster identity, drop tables, Slayer contracts and run upgrades use custom Godot Resources with stable string IDs. Future skill and recipe definitions should follow the same pattern. Save data must never use scene paths or array indices as permanent identities.

## Combat event flow
1. AutoCombat selects a valid enemy inside weapon range.
2. WeaponData supplies damage and cadence; the enemy receives one damage call.
3. EnemyController emits one death signal before freeing itself.
4. WaveManager reduces the active enemy count; AutoCombat awards special energy; ProgressionDirector awards run XP and rolls drops.
5. Slayer progress listens to the same authoritative death event.
6. At enough special energy, Q faces the player towards the nearest in-range target, then spends the configured cost once and applies damage within the weapon resource’s forward arc.

## Progression and save format

Run XP is temporary during the attempt. On defeat, the current prototype banks it into the local profile. Skill levels use the familiar OSRS cumulative XP threshold formula and are capped at 99.

Current profile schema:

```json
{
  "schema_version": 1,
  "permanent_skill_xp": {},
  "lifetime_kills": 0,
  "bronze_edge_unlocked": false
}
```

The profile writer writes a temporary file and then renames it into place. If a profile cannot be parsed or has an unsupported schema version, the game warns and starts with a fresh profile rather than attempting an unsafe migration.

## Current progression slice
- Slayer: the Goblin Clearance contract is defined in `data/slayer/goblin_clearance.tres`; its reusable service tracks 15 kills and emits bonus rewards.
- Drops and inventory: goblin loot is defined by `data/drops/goblin_drop_table.tres`; InventoryService stores item counts and validates crafting costs atomically.
- Skills: Attack, Strength, Defence, Hitpoints and Slayer earn run XP from kills.
- Drops: goblins can drop coins, copper ore and bones.
- Crafting: one Bronze Edge recipe consumes 5 ore, 3 bones and 30 coins, then grants a weapon damage bonus.
- Meta: permanent skill XP, lifetime kills and the crafted unlock are stored between launches.
- Combat feedback: directional crescent slashes for regular attacks and a configurable forward-facing Whirlwind sweep; player and goblin rigs respond with matching AnimationPlayer actions. Damage numbers remain separate world-space feedback.
- Level-up choices: each skill level gained offers one of up to three upgrades. Choices pause the world; selecting one resumes the run. Upgrades improve damage, attack speed, movement speed, maximum Hitpoints, special-energy gain or weapon reach. Ranks reset each run and are not banked into the persistent profile.

## Deliberate next steps
- Replace the procedural articulated rigs with authored, skinned character assets and AnimationTrees when licensed model assets are selected; add combat and ambient audio.
- Move crafting recipes, persistent profile operations and meta unlocks into dedicated resources/services.
- Add multiple monsters, weapon styles, projectile/magic delivery, Prayer, gathering nodes, bosses and a full run-results screen.
- Add automated gameplay tests for kill rewards, duplicate death prevention, recipe validation and profile migration.
