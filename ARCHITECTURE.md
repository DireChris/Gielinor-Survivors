# Gielinor Survivors — Architecture

## Runtime boundaries

The game is split into four layers. Systems communicate through typed signals or narrow public methods rather than reaching into unrelated nodes.

### Presentation
- `PlayerController`: movement and player Hitpoints.
- `OrbitCamera`: third-person orbit and zoom.
- `GameHUD`: presents run state, skills, Slayer, inventory and special energy.
- Character/enemy scenes: visual rigs, animation and audio emitters.

Presentation does not decide drop rates, calculate damage or award permanent XP.

### Run systems
- `WaveManager`: wave spawning, intermission and defeat state.
- `AutoCombat`: weapon cadence, target selection, special energy and hit effects.
- `ProgressionDirector`: current prototype owner for run XP, Slayer task, drops, starter crafting and profile banking. Split into dedicated Slayer, Drop, Crafting and RunSkill services as those systems expand.
- `EnemyController`: movement, contact attacks, health and one authoritative death signal.

### Persistent profile
The progression director reads and writes a versioned JSON profile under Godot's `user://` directory. Run XP is banked when the player is defeated. The profile stores permanent skill XP, lifetime kills and the Bronze Edge unlock. A future `ProfileService` should own schema migrations, backups and atomic saves independently of run systems.

### Data definitions
Weapon balance is already held in `WeaponData` resources. Future monster, skill, drop-table, recipe and Slayer definitions should use custom Godot Resources with stable string IDs. Save data must never use scene paths or array indices as permanent identities.

## Combat event flow
1. AutoCombat selects a valid enemy inside weapon range.
2. WeaponData supplies damage and cadence; the enemy receives one damage call.
3. EnemyController emits one death signal before freeing itself.
4. WaveManager reduces the active enemy count; AutoCombat awards special energy; ProgressionDirector awards run XP and rolls drops.
5. Slayer progress listens to the same authoritative death event.
6. At enough special energy, Q spends the configured cost once and applies area damage.

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
- Slayer: one 15-Goblin contract; completion grants bonus Slayer XP and coins.
- Skills: Attack, Strength, Defence, Hitpoints and Slayer earn run XP from kills.
- Drops: goblins can drop coins, copper ore and bones.
- Crafting: one Bronze Edge recipe consumes 5 ore, 3 bones and 30 coins, then grants a weapon damage bonus.
- Meta: permanent skill XP, lifetime kills and the crafted unlock are stored between launches.
- Combat feedback: damage numbers plus expanding gold impact rings for regular attacks and specials.

## Deliberate next steps
- Add a level-up choice flow with upgrade definitions and a pause/selection state.
- Replace placeholder geometry with rigged player and monster models, animation trees and audio.
- Separate Slayer contracts, drop tables, inventory, crafting recipes, profile service and meta unlock catalogue into independent resources/services.
- Add multiple monsters, weapon styles, projectile/magic delivery, Prayer, gathering nodes, bosses and a full run-results screen.
- Add automated gameplay tests for kill rewards, duplicate death prevention, recipe validation and profile migration.
