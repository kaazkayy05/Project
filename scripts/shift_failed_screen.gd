extends CanvasLayer

signal return_requested
signal leave_requested

const TEXT := Color("#e4e7ed")

var card := PanelContainer.new()
var jobs := Label.new()
var pending := Label.new()
var return_button := Button.new()
var leave_button := Button.new()


func box(fill: Color, border: Color, padding: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_content_margin_all(padding)
	return style


func _ready() -> void:
	layer = 2
	visible = false

	var dimmer := ColorRect.new()
	dimmer.color = Color("#080c17")
	dimmer.color.a = 0.72
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var margins := MarginContainer.new()
	dimmer.add_child(margins)
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margins.add_theme_constant_override("margin_" + side, 24)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margins.add_child(scroll)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)

	card.add_theme_stylebox_override("panel",
		box(Color("#080c17"), Color("#5a4937"), 24.0))
	center.add_child(card)

	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 20)
	card.add_child(contents)

	var heading := Label.new()
	heading.text = "SHIFT FAILED"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.add_theme_font_size_override("font_size", 36)
	heading.add_theme_color_override("font_color", TEXT)
	contents.add_child(heading)

	var explanation := Label.new()
	explanation.text = "6 AM. Your shift is over. You never made it out."
	explanation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.add_theme_font_size_override("font_size", 20)
	explanation.add_theme_color_override("font_color", TEXT)
	contents.add_child(explanation)

	jobs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	jobs.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	jobs.add_theme_font_size_override("font_size", 22)
	jobs.add_theme_color_override("font_color", TEXT)
	contents.add_child(jobs)

	return_button.text = "Return to Lobby"
	return_button.pressed.connect(func(): return_requested.emit())
	contents.add_child(return_button)

	leave_button.text = "Leave Lobby"
	leave_button.pressed.connect(func(): leave_requested.emit())
	contents.add_child(leave_button)

	for button in [return_button, leave_button]:
		button.custom_minimum_size.y = 48
		button.add_theme_font_size_override("font_size", 20)
		button.add_theme_color_override("font_color", TEXT)
		button.add_theme_color_override("font_disabled_color", TEXT)
		button.add_theme_color_override("font_hover_color", Color("#ffffff"))
		button.add_theme_color_override("font_pressed_color", Color("#ffffff"))
		button.add_theme_stylebox_override("normal",
			box(Color("#11345e"), Color("#5a4937"), 12.0))
		button.add_theme_stylebox_override("hover",
			box(Color("#11345e"), Color("#b7c0cf"), 12.0))
		button.add_theme_stylebox_override("pressed",
			box(Color("#080c17"), Color("#475c7d"), 12.0))
		button.add_theme_stylebox_override("disabled",
			box(Color("#080c17"), Color("#475c7d"), 12.0))
		button.add_theme_stylebox_override("focus",
			box(Color(0, 0, 0, 0), Color("#b7c0cf"), 0.0))

	leave_button.add_theme_stylebox_override("normal",
		box(Color("#080c17"), Color("#5a4937"), 12.0))

	pending.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pending.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pending.add_theme_color_override("font_color", Color("#b7c0cf"))
	contents.add_child(pending)


func update_result(active: bool, completed: int, target: int,
		busy: bool) -> void:
	var opening := active and not visible
	visible = active
	if not active:
		return

	# Reserve room for margins and a vertical scrollbar.
	card.custom_minimum_size.x = minf(
		560.0, maxf(0.0, get_viewport().get_visible_rect().size.x - 64.0))
	jobs.text = "Completed jobs: %d/%d" % [completed, target]
	return_button.disabled = busy
	leave_button.disabled = busy
	pending.text = "Updating lobby..." if busy else ""

	if opening and not busy:
		return_button.grab_focus()
