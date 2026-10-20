extends Node

const Player = preload("res://scripts/player.gd")
const Cemetery = preload("res://scripts/cemetery.gd")
const DEFAULT_SECONDS := 720.0

var server := false
var peer: WebSocketMultiplayerPeer
var players: Dictionary = {}
var roster: Dictionary = {}
var phase := "lobby"
var elapsed := 0.0
var duration := DEFAULT_SECONDS
var tick := 0.0
var connecting := 0.0
var admitted := false
var notice := ""
var world := Node3D.new()
var panel := VBoxContainer.new()
var status := Label.new()
var hud := Label.new()
var url := LineEdit.new()
var connect_button := Button.new()
var ready_button := Button.new()
var resume_button := Button.new()
var leave_button := Button.new()
var detail := Label.new()


func _ready() -> void:
	add_child(world)
	var cemetery := Node3D.new()
	cemetery.set_script(Cemetery)
	world.add_child(cemetery)
	build_ui()
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected)
	multiplayer.connection_failed.connect(connection_failed)
	multiplayer.server_disconnected.connect(server_lost)

	var port := 9080
	for argument in OS.get_cmdline_user_args():
		if argument == "--server":
			server = true
		elif argument.begins_with("--shift-seconds="):
			duration = argument.get_slice("=", 1).to_float()
		elif argument.begins_with("--port="):
			port = argument.get_slice("=", 1).to_int()
	if server:
		if duration <= 0 or not is_finite(duration) or port < 1 or port > 65535:
			push_error("Invalid server duration or port.")
			get_tree().quit(1)
			return
		peer = WebSocketMultiplayerPeer.new()
		var result := peer.create_server(port)
		if result != OK:
			push_error("Server failed to listen: " + error_string(result))
			get_tree().quit(1)
			return
		multiplayer.multiplayer_peer = peer
		print("Graveyard Shift server listening on TCP ", port,
			"; shift duration ", duration, " seconds.")
	refresh_ui()


func build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var background := PanelContainer.new()
	background.position = Vector2(16, 16)
	background.custom_minimum_size = Vector2(680, 0)
	canvas.add_child(background)
	background.add_child(panel)
	panel.add_child(status)
	panel.add_child(hud)
	detail.text = (
		"FOUNDATION PROTOTYPE\n"
		+ "Playable: walk together, switch tools, test flashlights and shared time.\n"
		+ "At 6 AM everyone loses. There is no win condition yet.\n"
		+ "Graves, gate, shed and bell are scenery. No tasks, creature or voice.\n"
		+ "WASD: walk | Mouse: look | 1: flashlight | 2: shovel\n"
		+ "F: toggle equipped flashlight | Esc: release mouse\n"
		+ "Both players must click Ready to start."
	)
	panel.add_child(detail)
	url.text = "ws://127.0.0.1:9080"
	url.placeholder_text = "Dedicated server ws:// or wss:// URL"
	panel.add_child(url)
	connect_button.text = "Connect to dedicated server"
	connect_button.pressed.connect(join_server)
	panel.add_child(connect_button)
	ready_button.text = "Ready"
	ready_button.pressed.connect(toggle_ready)
	panel.add_child(ready_button)
	resume_button.text = "Resume / capture mouse"
	resume_button.pressed.connect(func():
		if phase == "running" and admitted:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	)
	panel.add_child(resume_button)
	leave_button.text = "Leave session"
	leave_button.pressed.connect(func(): leave("You left the session."))
	panel.add_child(leave_button)


func join_server() -> void:
	var address := url.text.strip_edges()
	if not address.begins_with("ws://") and not address.begins_with("wss://"):
		notice = "Use a ws:// or wss:// server URL."
		refresh_ui()
		return
	peer = WebSocketMultiplayerPeer.new()
	var result := peer.create_client(address)
	if result != OK:
		peer = null
		notice = "Cannot begin connection: " + error_string(result)
	else:
		multiplayer.multiplayer_peer = peer
		connecting = 10.0
		notice = "Connecting..."
	refresh_ui()


func connected() -> void:
	notice = "Connected; waiting for server admission."
	refresh_ui()


func connection_failed() -> void:
	leave("Connection failed. Check URL, server, port, firewall and TLS.")


func server_lost() -> void:
	leave("Server connection closed. It may be unavailable or have rejected admission.")


func leave(message: String) -> void:
	if peer != null:
		peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	peer = null
	admitted = false
	connecting = 0
	roster.clear()
	clear_players()
	phase = "lobby"
	elapsed = 0
	notice = message
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	refresh_ui()


func peer_connected(id: int) -> void:
	if not server:
		return
	if roster.size() >= 2 or phase != "lobby":
		reject.rpc_id(id, "Session full or shift already started. Try again later.")
		return
	roster[id] = false
	notice = "Waiting for two ready players."
	print("Admitted player ", id, "; count ", roster.size())
	broadcast()


@rpc("authority", "call_remote", "reliable")
func reject(message: String) -> void:
	leave(message)


func peer_disconnected(id: int) -> void:
	if not server or not roster.has(id):
		return
	roster.erase(id)
	if phase == "running":
		phase = "lobby"
		elapsed = 0
		clear_players()
		notice = "Shift cancelled: teammate disconnected. Waiting in lobby."
		for member in roster:
			roster[member] = false
	elif roster.is_empty():
		phase = "lobby"
		elapsed = 0
		clear_players()
		notice = "Waiting for two players."
	elif phase == "lobby":
		for member in roster:
			roster[member] = false
		notice = "Player left. Readiness reset."
	print("Player left ", id, "; phase ", phase)
	broadcast()


func toggle_ready() -> void:
	if admitted and phase == "lobby":
		set_ready.rpc_id(1, not bool(roster.get(multiplayer.get_unique_id(), false)))


@rpc("any_peer", "call_remote", "reliable")
func set_ready(value: bool) -> void:
	var id := multiplayer.get_remote_sender_id()
	if not server or phase != "lobby" or not roster.has(id):
		return
	roster[id] = value
	if roster.size() == 2 and not roster.values().has(false):
		phase = "running"
		elapsed = 0
		notice = "Shift started."
		clear_players()
		var slot := 0
		for member in roster:
			var player = spawn_player(member, false)
			player.position = Vector3(-0.8 + slot * 1.6, 0.1, 12)
			slot += 1
		print("Shift started.")
	broadcast()


func spawn_player(id: int, is_local: bool):
	var player = CharacterBody3D.new()
	player.set_script(Player)
	player.name = str(id)
	player.local = is_local
	world.add_child(player)
	players[id] = player
	return player


func clear_players() -> void:
	for player in players.values():
		world.remove_child(player)
		player.queue_free()
	players.clear()


@rpc("any_peer", "call_remote", "reliable")
func submit_input(movement: Vector2, yaw: float, pitch: float,
		tool: int, light: bool) -> void:
	var id := multiplayer.get_remote_sender_id()
	if not server or phase != "running" or not players.has(id):
		return
	if not movement.is_finite() or not is_finite(yaw) or not is_finite(pitch):
		return
	var player = players[id]
	player.wish = movement.limit_length(1.0)
	player.look_yaw = wrapf(yaw, -PI, PI)
	player.look_pitch = clampf(pitch, -1.4, 1.4)
	player.tool = clampi(tool, 0, 1)
	player.lamp_on = light
	player.input_age = 0


func broadcast() -> void:
	var poses := {}
	for id in players:
		poses[id] = players[id].state()
	for id in roster:
		snapshot.rpc_id(id, phase, elapsed, duration, roster, poses, notice)


@rpc("authority", "call_remote", "reliable")
func snapshot(new_phase: String, seconds: float, total: float,
		members: Dictionary, poses: Dictionary, message: String) -> void:
	var previous := phase
	phase = new_phase
	elapsed = seconds
	duration = total
	roster = members
	admitted = roster.has(multiplayer.get_unique_id())
	connecting = 0
	notice = message
	if phase != "running":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if phase == "lobby":
		clear_players()
	else:
		for id in poses:
			if not players.has(id):
				spawn_player(id, id == multiplayer.get_unique_id())
			players[id].receive(poses[id])
	if previous != phase:
		print("Session state: ", phase)
	refresh_ui()


func _physics_process(delta: float) -> void:
	if server and phase == "running":
		elapsed = minf(elapsed + delta, duration)
		if elapsed >= duration:
			phase = "ended"
			notice = "6 AM — SHIFT LOST. Prototype deadline reached."
			print(notice)
			broadcast()
		for player in players.values():
			player.simulate(delta, phase == "running")

	tick += delta
	if tick >= 0.05:
		tick = 0
		if server:
			broadcast()
		elif admitted and phase == "running":
			send_local_input()

	if connecting > 0:
		connecting -= delta
		if connecting <= 0:
			leave("Connection timed out. Check server address, port, firewall and TLS.")


func send_local_input() -> void:
	var id := multiplayer.get_unique_id()
	if not players.has(id):
		return
	var player = players[id]
	var movement := Vector2.ZERO
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and get_window().has_focus():
		movement = Input.get_vector(
			"move_left", "move_right", "move_forward", "move_back")
	submit_input.rpc_id(1, movement, player.look_yaw,
		player.look_pitch, player.tool, player.lamp_on)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("release_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if not admitted or phase != "running":
		return
	var id := multiplayer.get_unique_id()
	if not players.has(id) or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var player = players[id]
	if event is InputEventMouseMotion:
		player.look_yaw = wrapf(
			player.look_yaw - event.relative.x * 0.0025, -PI, PI)
		player.look_pitch = clampf(
			player.look_pitch - event.relative.y * 0.0025, -1.4, 1.4)
	if event.is_action_pressed("equip_flashlight"):
		player.tool = 0
	if event.is_action_pressed("equip_shovel"):
		player.tool = 1
	if event.is_action_pressed("toggle_flashlight") and player.tool == 0:
		player.lamp_on = not player.lamp_on
	player.apply_visuals()
	refresh_ui()


func refresh_ui() -> void:
	if server:
		panel.visible = false
		return
	status.text = notice
	var minutes := mini(360, int(elapsed / duration * 360.0))
	var hour := minutes / 60
	var clock := "%d:%02d AM" % [12 if hour == 0 else hour, minutes % 60]
	var equipped := "Flashlight"
	var id := multiplayer.get_unique_id()
	if players.has(id) and players[id].tool == 1:
		equipped = "Shovel"
	hud.text = "%s | Players: %d/2 | Tool: %s" % [
		clock, roster.size(), equipped]
	if phase == "lobby" and admitted:
		hud.text += " | Ready: %d/2" % roster.values().count(true)
	url.visible = peer == null
	connect_button.visible = peer == null
	ready_button.visible = admitted and phase == "lobby"
	ready_button.text = "Cancel ready" if roster.get(id, false) else "Ready"
	resume_button.visible = admitted and phase == "running"
	leave_button.visible = peer != null
