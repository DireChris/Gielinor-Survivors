extends CanvasLayer

## Pause-safe overlay for selecting one of the offered run upgrades.

@export var upgrade_director_path: NodePath

var _upgrade_director: RunUpgradeDirector
var _overlay: ColorRect
var _context_label: Label
var _choice_container: HBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_upgrade_director = get_node_or_null(upgrade_director_path) as RunUpgradeDirector
	if _upgrade_director == null:
		push_error("LevelUpChoiceUI requires a valid RunUpgradeDirector reference.")
		return

	_build_interface()
	_upgrade_director.choices_available.connect(_on_choices_available)
	_upgrade_director.choices_closed.connect(_on_choices_closed)


func _build_interface() -> void:
	_overlay = ColorRect.new()
	_overlay.color = Color(0.015, 0.013, 0.01, 0.86)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	add_child(_overlay)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -510.0
	panel.offset_top = -245.0
	panel.offset_right = 510.0
	panel.offset_bottom = 245.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.075, 0.068, 0.052, 0.99)
	panel_style.border_color = Color(0.72, 0.55, 0.25, 1.0)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(5)
	panel_style.content_margin_left = 22.0
	panel_style.content_margin_right = 22.0
	panel_style.content_margin_top = 20.0
	panel_style.content_margin_bottom = 20.0
	panel.add_theme_stylebox_override("panel", panel_style)
	_overlay.add_child(panel)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 12)
	panel.add_child(stack)

	var heading := Label.new()
	heading.text = "A MOMENT OF CLARITY"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color", Color(0.95, 0.79, 0.43))
	heading.add_theme_font_size_override("font_size", 26)
	stack.add_child(heading)

	_context_label = Label.new()
	_context_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_context_label.add_theme_color_override("font_color", Color(0.87, 0.85, 0.76))
	_context_label.add_theme_font_size_override("font_size", 15)
	stack.add_child(_context_label)

	var instruction := Label.new()
	instruction.text = "CHOOSE ONE UPGRADE — THE WORLD WILL RESUME AFTER YOUR SELECTION"
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction.add_theme_color_override("font_color", Color(0.68, 0.65, 0.56))
	instruction.add_theme_font_size_override("font_size", 11)
	stack.add_child(instruction)

	stack.add_child(HSeparator.new())

	_choice_container = HBoxContainer.new()
	_choice_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_choice_container.add_theme_constant_override("separation", 14)
	stack.add_child(_choice_container)


func _on_choices_available(upgrades: Array[RunUpgradeData], context_text: String) -> void:
	_context_label.text = context_text
	for child in _choice_container.get_children():
		child.queue_free()

	for upgrade in upgrades:
		var current_rank := int(_upgrade_director.upgrade_ranks.get(upgrade.upgrade_id, 0))
		var button := Button.new()
		button.custom_minimum_size = Vector2(285.0, 270.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_stylebox_override("normal", _make_card_style(
			Color(0.12, 0.105, 0.078, 1.0),
			Color(0.55, 0.43, 0.23, 1.0)
		))
		button.add_theme_stylebox_override("hover", _make_card_style(
			Color(0.19, 0.16, 0.105, 1.0),
			Color(0.94, 0.74, 0.34, 1.0)
		))
		button.add_theme_stylebox_override("pressed", _make_card_style(
			Color(0.23, 0.19, 0.12, 1.0),
			Color(1.0, 0.82, 0.42, 1.0)
		))
		button.pressed.connect(_on_upgrade_button_pressed.bind(upgrade.upgrade_id))
		_choice_container.add_child(button)

		var content := VBoxContainer.new()
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content.add_theme_constant_override("separation", 12)
		button.add_child(content)

		var name_label := Label.new()
		name_label.text = upgrade.display_name.to_upper()
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_color_override("font_color", Color(0.96, 0.79, 0.42))
		name_label.add_theme_font_size_override("font_size", 18)
		content.add_child(name_label)

		var description_label := Label.new()
		description_label.text = upgrade.description
		description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		description_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		description_label.add_theme_color_override("font_color", Color(0.89, 0.87, 0.79))
		description_label.add_theme_font_size_override("font_size", 14)
		content.add_child(description_label)

		var rank_label := Label.new()
		rank_label.text = "RANK %d  →  %d / %d" % [
			current_rank,
			current_rank + 1,
			upgrade.max_rank
		]
		rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rank_label.add_theme_color_override("font_color", Color(0.72, 0.78, 0.63))
		rank_label.add_theme_font_size_override("font_size", 12)
		content.add_child(rank_label)

		var select_label := Label.new()
		select_label.text = "SELECT UPGRADE"
		select_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		select_label.add_theme_color_override("font_color", Color(0.94, 0.83, 0.59))
		select_label.add_theme_font_size_override("font_size", 11)
		content.add_child(select_label)

	_overlay.visible = true
	if _choice_container.get_child_count() > 0:
		var first_button := _choice_container.get_child(0) as Button
		if first_button != null:
			first_button.grab_focus()


func _make_card_style(background_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 14.0
	style.content_margin_bottom = 14.0
	return style


func _on_upgrade_button_pressed(upgrade_id: StringName) -> void:
	if is_instance_valid(_upgrade_director):
		_upgrade_director.choose_upgrade(upgrade_id)


func _on_choices_closed() -> void:
	if is_instance_valid(_overlay):
		_overlay.visible = false
