extends CanvasLayer

## Presentation-only OSRS-inspired HUD.

@export var player_path: NodePath
@export var camera_path: NodePath
@export var wave_manager_path: NodePath
@export var combat_path: NodePath
@export var progression_path: NodePath
@export var upgrade_director_path: NodePath

var _player: PlayerController
var _camera_rig: Node3D
var _wave_manager: WaveManager
var _combat: AutoCombat
var _progression: ProgressionDirector
var _upgrade_director: RunUpgradeDirector
var _health_label: Label
var _wave_label: Label
var _special_label: Label
var _special_bar: ProgressBar
var _status_label: Label
var _camera_label: Label
var _progression_label: Label
var _upgrade_label: Label


func _ready() -> void:
	_player = get_node_or_null(player_path) as PlayerController
	_camera_rig = get_node_or_null(camera_path) as Node3D
	_wave_manager = get_node_or_null(wave_manager_path) as WaveManager
	_combat = get_node_or_null(combat_path) as AutoCombat
	_progression = get_node_or_null(progression_path) as ProgressionDirector
	_upgrade_director = get_node_or_null(upgrade_director_path) as RunUpgradeDirector
	_build_hud()


func _process(_delta: float) -> void:
	if is_instance_valid(_player):
		var pos := _player.global_position
		var speed := Vector2(_player.velocity.x, _player.velocity.z).length()
		_status_label.text = "POSITION  X %5.1f   Z %5.1f\nMOVEMENT  %4.1f m/s" % [pos.x, pos.z, speed]
		_health_label.text = "HITPOINTS  %d / %d" % [_player.current_health, _player.max_health]
		if _player.is_dead:
			_health_label.text += "  -  DEFEATED"
	if is_instance_valid(_wave_manager):
		_wave_label.text = _wave_manager.get_status_text()
	if is_instance_valid(_combat):
		_special_bar.value = _combat.special_energy
		_special_label.text = "SPECIAL  %d%%  -  Q" % roundi(_combat.special_energy)
	if is_instance_valid(_progression):
		_progression_label.text = _progression.get_progression_text()
		if is_instance_valid(_combat):
			_combat.damage_bonus = _progression.weapon_damage_bonus
	if is_instance_valid(_upgrade_director):
		_upgrade_label.text = _upgrade_director.get_upgrade_summary_text()
	if is_instance_valid(_camera_rig):
		var arm := _camera_rig.get_node_or_null("YawPivot/PitchPivot/SpringArm3D") as SpringArm3D
		if arm != null:
			_camera_label.text = "CAMERA DISTANCE  %.1f" % arm.spring_length


func _build_hud() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(18.0, 18.0)
	panel.custom_minimum_size = Vector2(390.0, 0.0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.052, 0.045, 0.94)
	style.border_color = Color(0.55, 0.43, 0.22, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 6)
	panel.add_child(stack)
	var title := Label.new()
	title.text = "GIELINOR SURVIVORS"
	title.add_theme_color_override("font_color", Color(0.91, 0.77, 0.43))
	title.add_theme_font_size_override("font_size", 19)
	stack.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "LUMBRIDGE FRONTIER  •  SURVIVAL"
	subtitle.add_theme_color_override("font_color", Color(0.68, 0.65, 0.55))
	subtitle.add_theme_font_size_override("font_size", 10)
	stack.add_child(subtitle)
	stack.add_child(HSeparator.new())
	var controls := Label.new()
	controls.text = "WASD / ARROWS Move   |   SHIFT Sprint\nMIDDLE MOUSE Orbit   |   WHEEL Zoom\nQ Special attack   |   C Craft Bronze Edge"
	controls.add_theme_color_override("font_color", Color(0.84, 0.83, 0.76))
	controls.add_theme_font_size_override("font_size", 11)
	stack.add_child(controls)
	stack.add_child(HSeparator.new())
	_wave_label = _add_label(stack, "WAVE 01  |  PREPARING", Color(0.93, 0.77, 0.42), 12)
	_health_label = _add_label(stack, "HITPOINTS  100 / 100", Color(0.92, 0.42, 0.35), 12)
	_special_label = _add_label(stack, "SPECIAL  0%  -  Q", Color(0.80, 0.79, 0.68), 11)
	_special_bar = ProgressBar.new()
	_special_bar.min_value = 0
	_special_bar.max_value = 100
	_special_bar.show_percentage = false
	_special_bar.custom_minimum_size = Vector2(350, 14)
	stack.add_child(_special_bar)
	stack.add_child(HSeparator.new())
	_progression_label = _add_label(stack, "SKILLS  ATK 1  STR 1  DEF 1  HP 1", Color(0.78, 0.83, 0.68), 10)
	_progression_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_upgrade_label = _add_label(stack, "UPGRADES  NONE YET", Color(0.83, 0.72, 0.48), 10)
	_upgrade_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label = _add_label(stack, "", Color(0.71, 0.82, 0.67), 10)
	_camera_label = _add_label(stack, "", Color(0.70, 0.70, 0.68), 9)


func _add_label(parent: VBoxContainer, value: String, colour: Color, size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_color_override("font_color", colour)
	label.add_theme_font_size_override("font_size", size)
	parent.add_child(label)
	return label
