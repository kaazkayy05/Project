extends CanvasLayer

const SOFTNESS_SHADER = preload("res://shaders/visual_definition.gdshader")

@export var effect_enabled := true
@export_range(0.0, 2.0, 0.05) var radius_at_720p := 0.9
@export_range(0.0, 1.0, 0.05) var strength := 0.65
@export_range(0.0, 0.3, 0.01) var scanline_strength := 0.10
@export_range(2.0, 8.0, 0.25) var scanline_spacing := 3.0
@export_range(0.0, 0.1, 0.005) var grain_strength := 0.025
@export_range(0.0, 0.5, 0.01) var tracking_frequency := 0.12
@export_range(0.0, 0.3, 0.01) var tracking_strength := 0.12
@export_range(0.0, 2.0, 0.05) var instability := 0.35
@export_range(0.0, 2.0, 0.05) var color_separation := 0.65

var surface: ColorRect
var softness_material: ShaderMaterial


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		set_process(false)
		set_process_input(false)
		return

	# The existing HUD and map use CanvasLayer 1.
	# Layer 0 processes the 3D image before that interface is drawn.
	layer = 0

	softness_material = ShaderMaterial.new()
	softness_material.shader = SOFTNESS_SHADER

	surface = ColorRect.new()
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	surface.material = softness_material
	add_child(surface)
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	apply_settings()


func _process(_delta: float) -> void:
	# Also allows tuning through Godot's Remote Inspector.
	apply_settings()


func apply_settings() -> void:
	if surface == null:
		return

	surface.visible = effect_enabled and (
		(radius_at_720p > 0.0 and strength > 0.0)
		or scanline_strength > 0.0
		or grain_strength > 0.0
		or (tracking_frequency > 0.0 and tracking_strength > 0.0)
		or instability > 0.0
		or color_separation > 0.0
	)
	softness_material.set_shader_parameter("radius_at_720p", radius_at_720p)
	softness_material.set_shader_parameter("strength", strength)
	softness_material.set_shader_parameter("scanline_strength", scanline_strength)
	softness_material.set_shader_parameter("scanline_spacing", scanline_spacing)
	softness_material.set_shader_parameter("grain_strength", grain_strength)
	softness_material.set_shader_parameter("tracking_frequency", tracking_frequency)
	softness_material.set_shader_parameter("tracking_strength", tracking_strength)
	softness_material.set_shader_parameter("instability", instability)
	softness_material.set_shader_parameter("color_separation", color_separation)


func _input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if not event is InputEventKey:
		return
	if event.pressed and not event.echo and event.physical_keycode == KEY_V:
		effect_enabled = not effect_enabled
		apply_settings()
		print("Recorded-footage treatment: ", "enabled" if effect_enabled else "original")
		get_viewport().set_input_as_handled()
