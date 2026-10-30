extends Node3D

const REACH := 3.0
const SWEEP_SECONDS := 8.0
const TARGET := 2
const SITES := [
	Vector3(-6, 0, 11),
	Vector3(6, 0, 11),
]

var jobs: Dictionary = {}
var completed := 0
var debris: Array = []
var supply := Node3D.new()


static func block(parent: Node3D, at: Vector3,
		size: Vector3, color: Color) -> void:
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	visual.material_override = material
	parent.add_child(visual)
	visual.position = at


static func make_broom(parent: Node3D) -> void:
	block(parent, Vector3(0, 0.75, 0),
		Vector3(0.035, 1.2, 0.035), Color("#5a4937"))
	block(parent, Vector3(0, 0.12, 0),
		Vector3(0.38, 0.18, 0.12), Color("#786458"))


func _ready() -> void:
	for index in range(SITES.size()):
		var site: Vector3 = SITES[index]
		add_target(
			site + Vector3(0, 0.065, 0.8),
			Vector3(1.5, 0.03, 2.4),
			index
		)

		var pieces: Array = []
		for piece_index in range(8):
			var piece := Node3D.new()
			add_child(piece)
			piece.position = site + Vector3(
				-0.45 + (piece_index % 2) * 0.9,
				0.085,
				0.05 + floori(piece_index / 2.0) * 0.5
			)
			block(piece, Vector3.ZERO,
				Vector3(0.22, 0.015, 0.12), Color("#5a4937"))
			pieces.append(piece)
		debris.append(pieces)

	add_child(supply)
	supply.position = Vector3(11, 0.1, -10)
	make_broom(supply)
	block(self, Vector3(11, 0.06, -10),
		Vector3(0.8, 0.08, 0.8), Color("#5a4937"))
	add_target(Vector3(11, 0.8, -10),
		Vector3(0.5, 1.4, 0.4), -1)
	reset()


func set_pickup_visible(available: bool) -> void:
	supply.visible = available


func add_target(at: Vector3, size: Vector3, site: int) -> void:
	var area := Area3D.new()
	area.collision_layer = 2
	area.collision_mask = 0
	area.monitoring = false
	area.set_meta("sweeping_target", site)
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	area.add_child(collision)
	add_child(area)
	area.position = at


func reset() -> void:
	jobs.clear()
	completed = 0
	update_debris()


func begin(member_ids: Array) -> void:
	reset()
	for index in range(member_ids.size()):
		jobs[member_ids[index]] = {
			"site": index,
			"seconds": 0.0,
			"done": false,
			"active": false,
			"borrowed": "",
			"returned": false,
		}
	update_debris()


func aimed_target(player) -> int:
	var origin: Vector3 = player.head.global_position
	var direction: Vector3 = -player.head.global_basis.z
	var query := PhysicsRayQueryParameters3D.create(
		origin, origin + direction * REACH, 3, [player.get_rid()])
	query.collide_with_areas = true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return -2
	var collider = hit["collider"]
	if not collider.has_meta("sweeping_target"):
		return -2
	return int(collider.get_meta("sweeping_target"))


func advance(delta: float, players: Dictionary) -> void:
	for id in jobs:
		if not players.has(id):
			continue

		var job: Dictionary = jobs[id]
		job["active"] = false
		var player = players[id]

		if bool(job["done"]):
			continue
		if not player.interact_held or player.input_age > 0.2:
			continue

		var target := aimed_target(player)

		if target == -1 and job["borrowed"] == "broom":
			if float(job["seconds"]) >= SWEEP_SECONDS:
				player.has_broom = false
				if player.tool == 2:
					player.tool = 0
				job["borrowed"] = ""
				job["returned"] = true
				job["done"] = true
				completed += 1
				print("Player ", id,
					" returned their broom; shared count ", completed)
				continue

		if bool(job["returned"]):
			continue

		if not player.has_broom and target == -1:
			player.has_broom = true
			job["borrowed"] = "broom"
			print("Player ", id, " borrowed a broom.")
			continue

		if not player.has_broom or job["borrowed"] != "broom":
			continue
		if player.tool != 2 or target != int(job["site"]):
			continue
		if float(job["seconds"]) >= SWEEP_SECONDS:
			continue

		job["active"] = true
		job["seconds"] = minf(
			float(job["seconds"]) + delta, SWEEP_SECONDS)
		if float(job["seconds"]) >= SWEEP_SECONDS:
			job["active"] = false

	update_debris()


func export_state() -> Dictionary:
	return {"jobs": jobs.duplicate(true), "completed": completed}


func receive_state(data: Dictionary) -> void:
	jobs = data.get("jobs", {}).duplicate(true)
	completed = int(data.get("completed", 0))
	update_debris()


func update_debris() -> void:
	for index in range(debris.size()):
		var visible_count := 0
		for job in jobs.values():
			if int(job["site"]) == index:
				visible_count = 8 - floori(
					float(job["seconds"]) / SWEEP_SECONDS * 8.0)
		for piece_index in range(debris[index].size()):
			debris[index][piece_index].visible = piece_index < visible_count


func describe(id: int, player) -> String:
	if not jobs.has(id):
		return ""
	var job: Dictionary = jobs[id]
	var count_text := "Completed jobs: %d/%d" % [completed, TARGET]
	if completed >= TARGET:
		count_text += " — test target reached; shift continues"
	if bool(job["done"]):
		return "Assignment complete — broom returned.\n%s" % count_text

	if float(job["seconds"]) >= SWEEP_SECONDS:
		var return_message := (
			"Sweeping finished — return your borrowed broom to the shed.\n%s"
			% count_text
		)
		if aimed_target(player) == -1:
			return_message += "\nPress E to return your borrowed broom."
		return return_message

	var percent := int(float(job["seconds"]) / SWEEP_SECONDS * 100.0)
	var message := "Sweep assigned grave — %d%% | M: map\n%s" % [
		percent, count_text]
	var target := aimed_target(player)
	if not player.has_broom:
		message += "\nCollect a broom inside the tool shed."
		if target == -1:
			message += "\nPress E to collect your broom."
	elif player.tool != 2:
		message += "\nBroom collected. Press 3 to equip it."
	elif target == int(job["site"]):
		message += "\nHold E to sweep."
	else:
		message += "\nBroom equipped. Look down at your assigned debris within 3 metres. M: map."
	return message
