extends Node3D
class_name CharacterRig

## Self-contained articulated low-poly character rig.
## Meshes are procedural primitives attached to animated pivots so the rig
## works in a clean clone without downloaded model or animation assets.

@export_enum("Player", "Goblin") var character_kind: String = "Player"

var _animation_player: AnimationPlayer
var _current_animation: StringName = &""
var _action_locked: bool = false
var _death_played: bool = false


func _ready() -> void:
	_build_character()
	_build_animations()
	_animation_player.animation_finished.connect(_on_animation_finished)
	_play_movement_animation(&"idle")


func _process(_delta: float) -> void:
	if _action_locked or _death_played:
		return

	var actor := get_parent() as CharacterBody3D
	if actor == null:
		_play_movement_animation(&"idle")
		return

	if actor is PlayerController and (actor as PlayerController).is_dead:
		play_action(&"death")
		return

	var horizontal_speed := Vector2(actor.velocity.x, actor.velocity.z).length()
	var moving_threshold := 0.35 if character_kind == "Player" else 0.25
	if horizontal_speed > moving_threshold:
		_play_movement_animation(&"run")
	else:
		_play_movement_animation(&"idle")


func play_action(action_name: StringName) -> void:
	if _animation_player == null or not _animation_player.has_animation(action_name):
		return
	if action_name == &"death":
		_death_played = true
	_action_locked = true
	_current_animation = action_name
	_animation_player.play(action_name, 0.06)


func _play_movement_animation(animation_name: StringName) -> void:
	if _animation_player == null or _current_animation == animation_name:
		return
	if not _animation_player.has_animation(animation_name):
		return
	_current_animation = animation_name
	_animation_player.play(animation_name, 0.12)


func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name == &"idle" or animation_name == &"run":
		return
	if animation_name == _current_animation:
		_action_locked = false
		_current_animation = &""


func _build_character() -> void:
	var goblin := character_kind == "Goblin"
	var tunic_color := Color(0.22, 0.30, 0.43) if not goblin else Color(0.22, 0.36, 0.18)
	var skin_color := Color(0.73, 0.57, 0.40) if not goblin else Color(0.38, 0.58, 0.25)
	var trouser_color := Color(0.25, 0.23, 0.20) if not goblin else Color(0.22, 0.28, 0.18)
	var boot_color := Color(0.22, 0.13, 0.08)
	var leather_color := Color(0.38, 0.22, 0.11)

	var torso := Node3D.new()
	torso.name = "TorsoPivot"
	torso.position = Vector3(0.0, 1.05, 0.0)
	add_child(torso)

	var torso_mesh := BoxMesh.new()
	torso_mesh.size = Vector3(0.66 if not goblin else 0.58, 0.78 if not goblin else 0.68, 0.38)
	_add_mesh(torso, "Tunic", torso_mesh, tunic_color, Vector3.ZERO)

	var belt_mesh := BoxMesh.new()
	belt_mesh.size = Vector3(0.68 if not goblin else 0.60, 0.12, 0.41)
	_add_mesh(torso, "Belt", belt_mesh, leather_color, Vector3(0.0, -0.28, -0.01))

	var head_pivot := Node3D.new()
	head_pivot.name = "HeadPivot"
	head_pivot.position = Vector3(0.0, 0.46 if not goblin else 0.48, 0.0)
	torso.add_child(head_pivot)

	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.27 if not goblin else 0.25
	head_mesh.height = 0.54 if not goblin else 0.48
	_add_mesh(head_pivot, "Head", head_mesh, skin_color, Vector3(0.0, 0.05, 0.0))

	var eye_mesh := SphereMesh.new()
	eye_mesh.radius = 0.035 if not goblin else 0.045
	eye_mesh.height = eye_mesh.radius * 2.0
	var eye_color := Color(0.06, 0.05, 0.04)
	_add_mesh(head_pivot, "LeftEye", eye_mesh, eye_color, Vector3(-0.105, 0.07, -0.225))
	_add_mesh(head_pivot, "RightEye", eye_mesh, eye_color, Vector3(0.105, 0.07, -0.225))

	if goblin:
		var ear_mesh := CylinderMesh.new()
		ear_mesh.top_radius = 0.0
		ear_mesh.bottom_radius = 0.10
		ear_mesh.height = 0.42
		ear_mesh.radial_segments = 6
		_add_mesh(head_pivot, "LeftEar", ear_mesh, skin_color, Vector3(-0.30, 0.10, 0.0), Vector3(0.0, 0.0, deg_to_rad(62.0)))
		_add_mesh(head_pivot, "RightEar", ear_mesh, skin_color, Vector3(0.30, 0.10, 0.0), Vector3(0.0, 0.0, deg_to_rad(-62.0)))
	else:
		var hair_mesh := SphereMesh.new()
		hair_mesh.radius = 0.275
		hair_mesh.height = 0.24
		_add_mesh(head_pivot, "Hair", hair_mesh, Color(0.28, 0.17, 0.09), Vector3(0.0, 0.25, 0.01))

	var left_arm := _make_limb("LeftArmPivot", torso, Vector3(-0.41, 0.27, 0.0), 0.62, skin_color)
	var right_arm := _make_limb("RightArmPivot", torso, Vector3(0.41, 0.27, 0.0), 0.62, skin_color)

	var arm_trim := BoxMesh.new()
	arm_trim.size = Vector3(0.22, 0.15, 0.23)
	_add_mesh(left_arm, "Bracer", arm_trim, leather_color, Vector3(0.0, -0.45, 0.0))
	_add_mesh(right_arm, "Bracer", arm_trim, leather_color, Vector3(0.0, -0.45, 0.0))

	var left_leg := _make_limb("LeftLegPivot", self, Vector3(-0.19, 0.70, 0.0), 0.72, trouser_color)
	var right_leg := _make_limb("RightLegPivot", self, Vector3(0.19, 0.70, 0.0), 0.72, trouser_color)

	var boot_mesh := BoxMesh.new()
	boot_mesh.size = Vector3(0.27, 0.17, 0.40)
	_add_mesh(left_leg, "Boot", boot_mesh, boot_color, Vector3(0.0, -0.68, -0.045))
	_add_mesh(right_leg, "Boot", boot_mesh, boot_color, Vector3(0.0, -0.68, -0.045))

	if not goblin:
		_build_sword(right_arm)

	_animation_player = AnimationPlayer.new()
	_animation_player.name = "AnimationPlayer"
	_animation_player.root_node = NodePath("..")
	add_child(_animation_player)


func _make_limb(
	node_name: String,
	parent: Node3D,
	pivot_position: Vector3,
	length: float,
	limb_color: Color
) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = node_name
	pivot.position = pivot_position
	parent.add_child(pivot)

	var limb_mesh := CapsuleMesh.new()
	limb_mesh.radius = 0.13 if node_name.contains("Arm") else 0.17
	limb_mesh.height = length
	_add_mesh(pivot, "Limb", limb_mesh, limb_color, Vector3(0.0, -length * 0.48, 0.0))
	return pivot


func _build_sword(parent: Node3D) -> void:
	var grip := Node3D.new()
	grip.name = "SwordGrip"
	grip.position = Vector3(0.0, -0.57, -0.04)
	grip.rotation.z = deg_to_rad(-12.0)
	parent.add_child(grip)

	var blade := BoxMesh.new()
	blade.size = Vector3(0.095, 0.78, 0.055)
	_add_mesh(grip, "Blade", blade, Color(0.72, 0.78, 0.82), Vector3(0.0, -0.38, 0.0))

	var guard := BoxMesh.new()
	guard.size = Vector3(0.34, 0.065, 0.10)
	_add_mesh(grip, "Guard", guard, Color(0.72, 0.52, 0.20), Vector3(0.0, 0.015, 0.0))

	var handle := CylinderMesh.new()
	handle.top_radius = 0.045
	handle.bottom_radius = 0.045
	handle.height = 0.24
	_add_mesh(grip, "Handle", handle, Color(0.25, 0.13, 0.07), Vector3(0.0, 0.14, 0.0))


func _add_mesh(
	parent: Node3D,
	node_name: String,
	mesh: Mesh,
	tint: Color,
	mesh_position: Vector3,
	mesh_rotation: Vector3 = Vector3.ZERO
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = mesh_position
	instance.rotation = mesh_rotation

	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 0.88
	instance.material_override = material
	parent.add_child(instance)
	return instance


func _build_animations() -> void:
	var library := AnimationLibrary.new()
	library.add_animation(&"idle", _make_idle_animation())
	library.add_animation(&"run", _make_run_animation())
	library.add_animation(&"attack", _make_attack_animation())
	library.add_animation(&"special", _make_special_animation())
	library.add_animation(&"death", _make_death_animation())
	_animation_player.add_animation_library(&"", library)


func _make_idle_animation() -> Animation:
	var animation := Animation.new()
	animation.length = 1.6
	animation.loop_mode = Animation.LOOP_LINEAR
	_add_track(animation, "TorsoPivot:position", [
		[0.0, Vector3(0.0, 1.05, 0.0)],
		[0.8, Vector3(0.0, 1.085, 0.0)],
		[1.6, Vector3(0.0, 1.05, 0.0)]
	])
	_add_track(animation, "LeftArmPivot:rotation", [
		[0.0, Vector3(0.02, 0.0, -0.04)],
		[0.8, Vector3(-0.03, 0.0, -0.02)],
		[1.6, Vector3(0.02, 0.0, -0.04)]
	])
	_add_track(animation, "RightArmPivot:rotation", [
		[0.0, Vector3(-0.02, 0.0, 0.04)],
		[0.8, Vector3(0.03, 0.0, 0.02)],
		[1.6, Vector3(-0.02, 0.0, 0.04)]
	])
	_add_track(animation, "LeftLegPivot:rotation", [
		[0.0, Vector3.ZERO],
		[1.6, Vector3.ZERO]
	])
	_add_track(animation, "RightLegPivot:rotation", [
		[0.0, Vector3.ZERO],
		[1.6, Vector3.ZERO]
	])
	return animation


func _make_run_animation() -> Animation:
	var animation := Animation.new()
	animation.length = 0.56
	animation.loop_mode = Animation.LOOP_LINEAR
	_add_track(animation, "TorsoPivot:position", [
		[0.0, Vector3(0.0, 1.04, 0.0)],
		[0.14, Vector3(0.0, 1.12, 0.0)],
		[0.28, Vector3(0.0, 1.04, 0.0)],
		[0.42, Vector3(0.0, 1.12, 0.0)],
		[0.56, Vector3(0.0, 1.04, 0.0)]
	])
	_add_track(animation, "LeftLegPivot:rotation", [
		[0.0, Vector3(0.72, 0.0, 0.0)],
		[0.28, Vector3(-0.72, 0.0, 0.0)],
		[0.56, Vector3(0.72, 0.0, 0.0)]
	])
	_add_track(animation, "RightLegPivot:rotation", [
		[0.0, Vector3(-0.72, 0.0, 0.0)],
		[0.28, Vector3(0.72, 0.0, 0.0)],
		[0.56, Vector3(-0.72, 0.0, 0.0)]
	])
	_add_track(animation, "LeftArmPivot:rotation", [
		[0.0, Vector3(-0.62, 0.0, 0.0)],
		[0.28, Vector3(0.62, 0.0, 0.0)],
		[0.56, Vector3(-0.62, 0.0, 0.0)]
	])
	_add_track(animation, "RightArmPivot:rotation", [
		[0.0, Vector3(0.62, 0.0, 0.0)],
		[0.28, Vector3(-0.62, 0.0, 0.0)],
		[0.56, Vector3(0.62, 0.0, 0.0)]
	])
	return animation


func _make_attack_animation() -> Animation:
	var animation := Animation.new()
	animation.length = 0.42
	_add_track(animation, "RightArmPivot:rotation", [
		[0.0, Vector3(-0.55, 0.0, -0.25)],
		[0.12, Vector3(-1.05, 0.0, -0.45)],
		[0.25, Vector3(1.25, 0.0, 0.34)],
		[0.42, Vector3.ZERO]
	])
	_add_track(animation, "TorsoPivot:rotation", [
		[0.0, Vector3(0.0, -0.12, 0.0)],
		[0.17, Vector3(0.0, 0.18, 0.0)],
		[0.42, Vector3.ZERO]
	])
	return animation


func _make_special_animation() -> Animation:
	var animation := Animation.new()
	animation.length = 0.62
	_add_track(animation, "LeftArmPivot:rotation", [
		[0.0, Vector3(0.0, 0.0, 0.25)],
		[0.18, Vector3(-1.30, 0.0, 0.80)],
		[0.38, Vector3(1.00, 0.0, 0.70)],
		[0.62, Vector3.ZERO]
	])
	_add_track(animation, "RightArmPivot:rotation", [
		[0.0, Vector3(-0.45, 0.0, -0.30)],
		[0.18, Vector3(-1.50, 0.0, -0.80)],
		[0.38, Vector3(1.15, 0.0, -0.70)],
		[0.62, Vector3.ZERO]
	])
	_add_track(animation, "TorsoPivot:rotation", [
		[0.0, Vector3(0.0, -0.18, 0.0)],
		[0.30, Vector3(0.0, 0.20, 0.0)],
		[0.62, Vector3.ZERO]
	])
	return animation


func _make_death_animation() -> Animation:
	var animation := Animation.new()
	animation.length = 0.72
	_add_track(animation, "TorsoPivot:position", [
		[0.0, Vector3(0.0, 1.05, 0.0)],
		[0.30, Vector3(0.0, 0.84, 0.0)],
		[0.72, Vector3(0.0, 0.52, 0.0)]
	])
	_add_track(animation, "TorsoPivot:rotation", [
		[0.0, Vector3.ZERO],
		[0.30, Vector3(-0.85, 0.0, 0.0)],
		[0.72, Vector3(-1.30, 0.0, 0.0)]
	])
	_add_track(animation, "LeftArmPivot:rotation", [
		[0.0, Vector3.ZERO],
		[0.25, Vector3(-0.40, 0.0, 1.20)],
		[0.72, Vector3(0.20, 0.0, 1.40)]
	])
	_add_track(animation, "RightArmPivot:rotation", [
		[0.0, Vector3.ZERO],
		[0.25, Vector3(-0.40, 0.0, -1.20)],
		[0.72, Vector3(0.20, 0.0, -1.40)]
	])
	return animation


func _add_track(animation: Animation, property_path: String, keys: Array) -> void:
	var track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track, NodePath(property_path))
	animation.track_set_interpolation_type(track, Animation.INTERPOLATION_CUBIC)
	for key in keys:
		animation.track_insert_key(track, float(key[0]), key[1])
