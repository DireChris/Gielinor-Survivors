extends Node
class_name WaveManager

## Endless wave director. Spawn requests are bounded by max_active_enemies;
## each enemy reports one death signal, which advances the wave state.

signal status_changed(status_text: String)

enum WaveState {
	PREPARING,
	SPAWNING,
	CLEARING,
	INTERMISSION,
	DEFEATED
}

@export_category("References")
@export var player_path: NodePath
@export var enemy_container_path: NodePath
@export var enemy_scene: PackedScene = preload("res://scenes/enemies/goblin.tscn")

@export_category("Wave Tuning")
@export_range(1, 30, 1) var starting_enemy_count: int = 4
@export_range(1, 20, 1) var additional_enemies_per_wave: int = 2
@export_range(1, 30, 1) var max_active_enemies: int = 8
@export_range(0.1, 5.0, 0.1) var spawn_interval: float = 0.9
@export_range(1.0, 15.0, 0.5) var intermission_duration: float = 4.0
@export_range(2.0, 30.0, 0.5) var spawn_min_distance: float = 10.0
@export_range(2.0, 35.0, 0.5) var spawn_max_distance: float = 14.0

var wave_number: int = 0
var spawned_count: int = 0
var enemies_to_spawn: int = 0
var alive_count: int = 0
var state: WaveState = WaveState.PREPARING

var _player: PlayerController
var _enemy_container: Node3D
var _time_remaining: float = 2.5


func _ready() -> void:
	_player = get_node_or_null(player_path) as PlayerController
	_enemy_container = get_node_or_null(enemy_container_path) as Node3D

	if _player == null:
		push_error("WaveManager: player_path must point to a PlayerController.")
		set_process(false)
		return

	if _enemy_container == null:
		push_error("WaveManager: enemy_container_path must point to a Node3D.")
		set_process(false)
		return

	_player.player_died.connect(_on_player_died)
	_emit_status()


func _process(delta: float) -> void:
	if state == WaveState.DEFEATED:
		return

	_time_remaining = maxf(0.0, _time_remaining - delta)

	match state:
		WaveState.PREPARING:
			if _time_remaining <= 0.0:
				_begin_wave()
		WaveState.SPAWNING:
			if (
				_time_remaining <= 0.0
				and spawned_count < enemies_to_spawn
				and alive_count < max_active_enemies
			):
				_spawn_enemy()
				_time_remaining = spawn_interval

			if spawned_count >= enemies_to_spawn:
				state = WaveState.CLEARING
				_emit_status()
		WaveState.CLEARING:
			if alive_count <= 0:
				state = WaveState.INTERMISSION
				_time_remaining = intermission_duration
				_emit_status()
		WaveState.INTERMISSION:
			if _time_remaining <= 0.0:
				_begin_wave()


func get_status_text() -> String:
	match state:
		WaveState.PREPARING:
			return "WAVE 01  |  PREPARING"
		WaveState.SPAWNING:
			return "WAVE %02d  |  SPAWNING %d/%d  |  ALIVE %d" % [
				wave_number,
				spawned_count,
				enemies_to_spawn,
				alive_count
			]
		WaveState.CLEARING:
			return "WAVE %02d  |  ENEMIES LEFT %d" % [wave_number, alive_count]
		WaveState.INTERMISSION:
			return "WAVE %02d CLEARED  |  NEXT IN %dS" % [
				wave_number,
				ceili(_time_remaining)
			]
		WaveState.DEFEATED:
			return "DEFEATED  |  REACHED WAVE %02d" % wave_number

	return "GIELINOR SURVIVORS"


func _begin_wave() -> void:
	wave_number += 1
	enemies_to_spawn = starting_enemy_count + (wave_number - 1) * additional_enemies_per_wave
	spawned_count = 0
	state = WaveState.SPAWNING
	_time_remaining = 0.35
	_emit_status()


func _spawn_enemy() -> void:
	var enemy := enemy_scene.instantiate() as EnemyController
	if enemy == null:
		push_error("WaveManager: enemy_scene must instantiate an EnemyController.")
		state = WaveState.DEFEATED
		_emit_status()
		return

	var angle := randf_range(0.0, TAU)
	var distance := randf_range(spawn_min_distance, spawn_max_distance)
	var spawn_offset := Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)

	_enemy_container.add_child(enemy)
	enemy.global_position = _player.global_position + spawn_offset
	enemy.initialize(_player, wave_number)
	enemy.died.connect(_on_enemy_died)

	spawned_count += 1
	alive_count += 1
	_emit_status()


func _on_enemy_died(_enemy: EnemyController) -> void:
	alive_count = maxi(0, alive_count - 1)
	_emit_status()


func _on_player_died() -> void:
	state = WaveState.DEFEATED
	_emit_status()


func _emit_status() -> void:
	status_changed.emit(get_status_text())
