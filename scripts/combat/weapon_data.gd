extends Resource
class_name WeaponData

## Reusable weapon tuning data. Runtime combat reads this resource rather
## than embedding weapon balance values in the combat manager.

enum TargetPolicy {
	NEAREST,
	LOWEST_HEALTH
}

@export var weapon_id: StringName = &"bronze_sword"
@export var display_name: String = "Bronze Sword"
@export_enum("Melee", "Ranged", "Magic") var attack_style: String = "Melee"

@export_category("Auto Attack")
@export_range(1, 100, 1) var damage: int = 8
@export_range(0.1, 5.0, 0.05) var attack_interval: float = 0.85
@export_range(0.5, 15.0, 0.1) var attack_range: float = 3.4
@export var target_policy: TargetPolicy = TargetPolicy.NEAREST

@export_category("Special Attack")
@export var special_name: String = "Whirlwind"
@export_range(1.0, 10.0, 0.05) var special_damage_multiplier: float = 1.75
@export_range(1.0, 15.0, 0.1) var special_radius: float = 5.5
@export_range(1.0, 100.0, 1.0) var special_cost: float = 50.0
