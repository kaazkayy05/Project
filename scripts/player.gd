extends CharacterBody3D

var local := false
var tool := 0
var lamp_on := true
var look_yaw := 0.0
var look_pitch := 0.0
var wish := Vector2.ZERO
var input_age := 0.0

var head := Node3D.new()
var camera := Camera3D.new()
var body := Node3D.new()
var flashlight := Node3D.new()
var shovel := Node3D.new()
var beam := SpotLight3D.new()


func piece(parent: Node3D, at: Vector3, size: Vector3,
		color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material_override = material
	parent.add_child(mesh)
	mesh.position = at


func _ready() -> void:
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.8
	collider.shape = capsule
	collider.position.y = 0.9
	add_child(collider)
	add_child(body)
	piece(body, Vector3(0, 0.95, 0), Vector3(0.5, 1.0, 0.35),
		Color(0.25, 0.38, 0.43))
	piece(body, Vector3(0, 1.65, 0), Vector3(0.35, 0.35, 0.35),
		Color(0.60, 0.48, 0.37))
	for x in [-0.15, 0.15]:
		piece(body, Vector3(x, 0.25, 0), Vector3(0.2, 0.5, 0.25),
			Color(0.13, 0.16, 0.19))
	body.visible = not local

	add_child(head)
	head.position.y = 1.6
	head.add_child(camera)
	camera.current = local
	camera.near = 0.05
	camera.fov = 75
	head.add_child(flashlight)
	head.add_child(shovel)
	piece(flashlight, Vector3(0.3, -0.25, -0.5),
		Vector3(0.12, 0.12, 0.4), Color(0.18, 0.19, 0.2))
	flashlight.add_child(beam)
	beam.position = Vector3(0.3, -0.25, -0.72)
	beam.light_energy = 3.0
	beam.spot_range = 18.0
	beam.spot_angle = 28.0
	piece(shovel, Vector3(0.32, -0.35, -0.6),
		Vector3(0.06, 1.0, 0.06), Color(0.38, 0.24, 0.12))
	piece(shovel, Vector3(0.32, -0.85, -0.6),
		Vector3(0.25, 0.3, 0.06), Color(0.45, 0.47, 0.49))
	apply_visuals()


func apply_visuals() -> void:
	rotation.y = look_yaw
	head.rotation.x = look_pitch
	flashlight.visible = tool == 0
	shovel.visible = tool == 1
	beam.visible = tool == 0 and lamp_on


func simulate(delta: float, active: bool) -> void:
	input_age += delta
	var movement := wish if active and input_age < 0.5 else Vector2.ZERO
	var direction := Basis(Vector3.UP, look_yaw) * Vector3(
		movement.x, 0, movement.y)
	velocity.x = direction.x * 4.0
	velocity.z = direction.z * 4.0
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = 0
	if active:
		move_and_slide()
	else:
		velocity = Vector3.ZERO
	apply_visuals()


func state() -> Array:
	return [position, look_yaw, look_pitch, tool, lamp_on]


func receive(data: Array) -> void:
	position = data[0]
	if not local:
		look_yaw = data[1]
		look_pitch = data[2]
		tool = data[3]
		lamp_on = data[4]
	apply_visuals()
