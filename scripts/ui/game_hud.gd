extends CanvasLayer

## Lightweight placeholder HUD using a muted OSRS-inspired palette.
## This will be replaced by the full tabbed interface in the UI phase.

@export var player_path: NodePath
@export var camera_path: NodePath

var _player: CharacterBody3D
var _camera_rig: Node3D
var _status_label: Label
var _camera_label: Label


func _ready() -> void:
	_player = get_node_or_null(player_path) as CharacterBody3D
	_camera_rig = get_node_or_null(camera_path) as Node3D
	_build_hud()


func _process(_delta: float) -> void:
	if is_instance_valid(_player) and _status_label != null:
		var p := _player.global_position
		var speed := Vector2(_player.velocity.x, _player.velocity.z).length()
		_status_label.text = "POSITION  X %5.1f   Z %5.1f\nMOVEMENT  %4.1f m/s" % [p.x, p.z, speed]

	if is_instance_valid(_camera_rig) and _camera_label != null:
		var arm := _camera_rig.get_node_or_null("YawPivot/PitchPivot/SpringArm3D") as SpringArm3D
		if arm != null:
			_camera_label.text = "CAMERA DISTANCE  %.1f" % arm.spring_length


func _build_hud() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(18.0, 18.0)
	panel.custom_minimum_size = Vector2(300.0, 0.0)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.055, 0.052, 0.045, 0.92)
	panel_style.border_color = Color(0.55, 0.43, 0.22, 0.95)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(3)
	panel_style.content_margin_left = 14.0
	panel_style.content_margin_right = 14.0
	panel_style.content_margin_top = 10.0
	panel_style.content_margin_bottom = 10.0
	panel.add_theme_stylebox_override("panel", panel_style)
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
	subtitle.text = "LUMBRIDGE FRONTIER  •  PROTOTYPE"
	subtitle.add_theme_color_override("font_color", Color(0.68, 0.65, 0.55))
	subtitle.add_theme_font_size_override("font_size", 10)
	stack.add_child(subtitle)

	var divider := HSeparator.new()
	stack.add_child(divider)

	var controls := Label.new()
	controls.text = "WASD / ARROWS   Move\nSHIFT                   Sprint\nMIDDLE MOUSE   Orbit camera\nWHEEL                  Zoom\nESC                       Release cursor"
	controls.add_theme_color_override("font_color", Color(0.84, 0.83, 0.76))
	controls.add_theme_font_size_override("font_size", 12)
	stack.add_child(controls)

	var status_divider := HSeparator.new()
	stack.add_child(status_divider)

	_status_label = Label.new()
	_status_label.add_theme_color_override("font_color", Color(0.71, 0.82, 0.67))
	_status_label.add_theme_font_size_override("font_size", 11)
	stack.add_child(_status_label)

	_camera_label = Label.new()
	_camera_label.add_theme_color_override("font_color", Color(0.70, 0.70, 0.68))
	_camera_label.add_theme_font_size_override("font_size", 10)
	stack.add_child(_camera_label)
