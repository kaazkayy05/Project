extends SubViewport

signal state_changed

const Player = preload("res://scripts/player.gd")
const Cemetery = preload("res://scripts/cemetery.gd")
const Sweeping = preload("res://scripts/sweeping.gd")

var roster: Dictionary = {}
var players: Dictionary = {}
var phase := "lobby"
var elapsed := 0.0
var duration := 720.0
var notice := ""
var generation := 0
var creator_id := 0

var world := Node3D.new()
var sweeping: Node3D


func _init() -> void:
	# Each session owns a separate physics space.
	world_3d = World3D.new()
	size = Vector2i(2, 2)
	render_target_update_mode = SubViewport.UPDATE_DISABLED
	gui_disable_input = true
	physics_object_picking = false


func _ready() -> void:
	add_child(world)

	var cemetery := Node3D.new()
	cemetery.set_script(Cemetery)
	world.add_child(cemetery)

	sweeping = Node3D.new()
	sweeping.set_script(Sweeping)
	world.add_child(sweeping)


func add_member(id: int) -> String:
	if roster.has(id):
		return ""
	if roster.size() >= 2 or phase != "lobby":
		return "Session full or shift already started. Try again later."

	roster[id] = false
	generation += 1
	for member in roster:
		roster[member] = false
	if creator_id == 0:
		creator_id = id
	notice = "Waiting for two ready players."
	print("Admitted player ", id, "; count ", roster.size())
	state_changed.emit()
	return ""


func remove_member(id: int) -> void:
	if not roster.has(id):
		return

	roster.erase(id)
	if creator_id == id:
		creator_id = 0 if roster.is_empty() else int(roster.keys()[0])

	var message := "Player left. Readiness reset."
	if phase == "running":
		message = "Shift cancelled: teammate left. Waiting in lobby."
	if roster.is_empty():
		message = "Waiting for two players."
	reset_to_lobby(message)

	print("Player left ", id, "; phase ", phase)
	state_changed.emit()


func reset_to_lobby(message: String) -> void:
	generation += 1
	phase = "lobby"
	elapsed = 0.0
	clear_players()
	for member in roster:
		roster[member] = false
	notice = message


func set_member_ready(id: int, value: bool) -> void:
	if phase != "lobby" or not roster.has(id):
		return

	roster[id] = value
	if roster.size() == 2 and not roster.values().has(false):
		generation += 1
		phase = "running"
		elapsed = 0.0
		notice = "Shift started."
		clear_players()

		var slot := 0
		for member in roster:
			var player = spawn_player(member)
			player.position = Vector3(-0.8 + slot * 1.6, 0.1, 12)
			slot += 1

		sweeping.begin(roster.keys())
		print("Shift started.")

	state_changed.emit()


func spawn_player(id: int):
	var player = CharacterBody3D.new()
	player.set_script(Player)
	player.name = str(id)
	player.local = false
	world.add_child(player)
	players[id] = player
	return player


func clear_players() -> void:
	for player in players.values():
		world.remove_child(player)
		player.queue_free()
	players.clear()
	sweeping.reset()


func accept_input(id: int, movement: Vector2, yaw: float, pitch: float,
		tool: int, light: bool, interact: bool) -> void:
	if phase != "running" or not roster.has(id) or not players.has(id):
		return
	if not movement.is_finite() or not is_finite(yaw) or not is_finite(pitch):
		return

	var player = players[id]
	player.wish = movement.limit_length(1.0)
	player.look_yaw = wrapf(yaw, -PI, PI)
	player.look_pitch = clampf(pitch, -1.4, 1.4)
	player.tool = clampi(tool, 0, 2 if player.has_broom else 1)
	player.lamp_on = light
	player.interact_held = interact
	player.input_age = 0


func advance(delta: float) -> void:
	if phase != "running":
		return

	elapsed = minf(elapsed + delta, duration)
	if elapsed >= duration:
		generation += 1
		phase = "ended"
		notice = "6 AM — SHIFT LOST. Prototype deadline reached."
		print(notice)

	# Preserve the existing simulation order and deadline behavior.
	for player in players.values():
		player.simulate(delta, phase == "running")

	if phase == "running":
		sweeping.advance(delta, players)
	else:
		state_changed.emit()


func export_snapshot() -> Dictionary:
	var poses := {}
	for id in players:
		poses[id] = players[id].state()

	return {
		"phase": phase,
		"elapsed": elapsed,
		"duration": duration,
		"roster": roster.duplicate(),
		"poses": poses,
		"notice": notice,
		"task_state": sweeping.export_state(),
	}
