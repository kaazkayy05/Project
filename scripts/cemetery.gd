extends Node3D


func box(at: Vector3, size: Vector3, color: Color,
		solid: bool = true) -> void:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material_override = material
	if solid:
		var body := StaticBody3D.new()
		add_child(body)
		body.position = at
		body.add_child(mesh)
		var collision := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size = size
		collision.shape = bounds
		body.add_child(collision)
	else:
		add_child(mesh)
		mesh.position = at


func _ready() -> void:
	var stone := Color(0.32, 0.34, 0.36)
	var wood := Color(0.23, 0.16, 0.10)
	box(Vector3(0, -0.25, 0), Vector3(30, 0.5, 32),
		Color(0.12, 0.17, 0.12))
	box(Vector3(0, 0.015, 0), Vector3(3, 0.02, 30),
		Color(0.29, 0.26, 0.21), false)
	box(Vector3(0, 0.025, 2), Vector3(27, 0.02, 2),
		Color(0.29, 0.26, 0.21), false)

	# Perimeter and closed scenery gate.
	for x in [-15.0, 15.0]:
		box(Vector3(x, 0.8, 0), Vector3(0.4, 1.6, 32), stone)
	box(Vector3(0, 0.8, -16), Vector3(30, 1.6, 0.4), stone)
	for x in [-8.5, 8.5]:
		box(Vector3(x, 0.8, 16), Vector3(13, 1.6, 0.4), stone)
	for x in [-2.0, 2.0]:
		box(Vector3(x, 1.4, 15.8), Vector3(0.5, 2.8, 0.5), stone)
	for x in range(-3, 4):
		box(Vector3(x * 0.5, 1.1, 15.8),
			Vector3(0.08, 2.2, 0.15), Color(0.12, 0.13, 0.15))
	box(Vector3(0, 1.8, 15.8), Vector3(4, 0.1, 0.15), stone)

	for x in [-10.0, -6.0, 6.0, 10.0]:
		for z in [-10.0, -5.0, 6.0, 11.0]:
			box(Vector3(x, 0.025, z + 0.8),
				Vector3(1.5, 0.04, 2.4), Color(0.20, 0.16, 0.12), false)
			box(Vector3(x, 0.6, z), Vector3(0.9, 1.2, 0.25), stone)

	# Solid shed with a visible recessed doorway.
	box(Vector3(11, 1.4, -13), Vector3(5, 2.8, 0.3), wood)
	for x in [8.5, 13.5]:
		box(Vector3(x, 1.4, -11), Vector3(0.3, 2.8, 4), wood)
	for x in [9.25, 12.75]:
		box(Vector3(x, 1.4, -9), Vector3(1.5, 2.8, 0.3), wood)
	box(Vector3(11, 2.6, -9), Vector3(2, 0.4, 0.3), wood)
	box(Vector3(11, 2.9, -11), Vector3(5.5, 0.3, 4.5), stone)

	# Bell frame and original block bell placeholder.
	for x in [-3.8, -2.2]:
		box(Vector3(x, 1.3, 11), Vector3(0.2, 2.6, 0.2), wood)
	box(Vector3(-3, 2.6, 11), Vector3(2, 0.2, 0.3), wood)
	box(Vector3(-3, 2.15, 11), Vector3(0.7, 0.6, 0.7),
		Color(0.55, 0.39, 0.12))

	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.025, 0.035, 0.055)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(0.5, 0.6, 0.8)
	environment.environment.ambient_light_energy = 0.45
	add_child(environment)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-55, -30, 0)
	moon.light_energy = 0.35
	add_child(moon)
