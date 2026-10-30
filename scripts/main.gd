extends Node

const Player = preload("res://scripts/player.gd")
const Cemetery = preload("res://scripts/cemetery.gd")
const Sweeping = preload("res://scripts/sweeping.gd")
const GraveyardMap = preload("res://scripts/graveyard_map.gd")
const LobbyServer = preload("res://scripts/lobby_server.gd")
const ShiftFailedScreen = preload("res://scripts/shift_failed_screen.gd")
const DEFAULT_SECONDS := 720.0

var server := false
var lobby: LobbyServer
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
var sweeping: Node3D
var task_hud := Label.new()
var task_message := ""
var map_view: Control
var map_graves: Array[Vector3] = []
var room_code := ""
var room_generation := 0
var room_creator := 0
var request_serial := 0
var pending_request := 0
var pending_action := ""
var room_entry := LineEdit.new()
var join_button := Button.new()
var room_info := Label.new()
var slot_status := Label.new()
var loss_screen: ShiftFailedScreen
var menu_title := Label.new()
var room_caption := Label.new()
var menu_style: StyleBoxFlat


func menu_box(fill: Color, border: Color, padding: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_content_margin_all(padding)
	return style


func _ready() -> void:
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

		lobby = LobbyServer.new()
		lobby.name = "LobbyServer"
		lobby.duration = duration
		lobby.snapshot_ready.connect(send_room_snapshot)
		lobby.reply_ready.connect(send_room_reply)
		add_child(lobby)
	else:
		add_child(world)
		var cemetery := Node3D.new()
		cemetery.set_script(Cemetery)
		world.add_child(cemetery)
		map_graves = cemetery.grave_positions
		sweeping = Node3D.new()
		sweeping.set_script(Sweeping)
		world.add_child(sweeping)

	build_ui()
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected)
	multiplayer.connection_failed.connect(connection_failed)
	multiplayer.server_disconnected.connect(server_lost)

	if server:
		var server_api := multiplayer as SceneMultiplayer
		server_api.server_relay = false
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
	background.custom_minimum_size = Vector2(560, 0)
	menu_style = menu_box(Color("#080c17"), Color("#5a4937"), 24.0)
	background.add_theme_stylebox_override("panel", menu_style)
	canvas.add_child(background)
	background.add_child(panel)
	panel.add_theme_constant_override("separation", 12)
	menu_title.text = "GRAVEYARD SHIFT"
	menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_title.add_theme_font_size_override("font_size", 30)
	menu_title.add_theme_color_override("font_color", Color("#e4e7ed"))
	panel.add_child(menu_title)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 14)
	status.add_theme_color_override("font_color", Color("#b7c0cf"))
	panel.add_child(status)
	room_caption.text = "ROOM CODE"
	room_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	room_caption.add_theme_font_size_override("font_size", 13)
	room_caption.add_theme_color_override("font_color", Color("#b7c0cf"))
	panel.add_child(room_caption)
	room_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	room_info.add_theme_font_size_override("font_size", 42)
	room_info.add_theme_color_override("font_color", Color("#e4e7ed"))
	panel.add_child(room_info)
	slot_status.add_theme_font_size_override("font_size", 18)
	slot_status.add_theme_constant_override("line_spacing", 12)
	slot_status.add_theme_color_override("font_color", Color("#e4e7ed"))
	panel.add_child(slot_status)
	panel.add_child(hud)
	panel.add_child(task_hud)
	detail.text = (
		"FOUNDATION PROTOTYPE\n"
		+ "Playable: collect a broom in the shed and sweep your assigned grave site.\n"
		+ "At 6 AM everyone loses. There is no win condition yet.\n"
		+ "Sweep, then return your borrowed broom to earn one completed job.\n"
		+ "WASD: walk | Mouse: look | 1: flashlight | 2: shovel | 3: broom\n"
		+ "F: flashlight | E: collect broom / hold to sweep | M: map | Esc: release mouse\n"
		+ "Both players must click Ready to start."
	)
	panel.add_child(detail)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_font_size_override("font_size", 14)
	detail.add_theme_color_override("font_color", Color("#b7c0cf"))
	hud.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	task_hud.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	url.text = "ws://127.0.0.1:9080"
	url.placeholder_text = "Dedicated server ws:// or wss:// URL"
	panel.add_child(url)
	room_entry.placeholder_text = "Room code"
	room_entry.max_length = 6
	panel.add_child(room_entry)
	connect_button.text = "Create Lobby"
	connect_button.pressed.connect(func(): begin_room_action("create"))
	panel.add_child(connect_button)
	join_button.text = "Join Lobby"
	join_button.pressed.connect(func(): begin_room_action("join"))
	panel.add_child(join_button)
	ready_button.text = "Ready"
	ready_button.pressed.connect(toggle_ready)
	panel.add_child(ready_button)
	resume_button.text = "Resume"
	resume_button.pressed.connect(func():
		if phase == "running" and admitted:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	)
	panel.add_child(resume_button)
	leave_button.text = "Leave Lobby"
	leave_button.pressed.connect(func(): begin_room_action("leave"))
	panel.add_child(leave_button)
	for button in [
		connect_button, join_button, ready_button, resume_button,
		leave_button
	]:
		button.custom_minimum_size.y = 44
		button.add_theme_font_size_override("font_size", 20)
		button.add_theme_color_override("font_color", Color("#e4e7ed"))
		button.add_theme_color_override("font_hover_color", Color("#ffffff"))
		button.add_theme_color_override("font_pressed_color", Color("#ffffff"))
		button.add_theme_stylebox_override("normal",
			menu_box(Color("#11345e"), Color("#475c7d"), 10.0))
		button.add_theme_stylebox_override("hover",
			menu_box(Color("#11345e"), Color("#b7c0cf"), 10.0))
		button.add_theme_stylebox_override("pressed",
			menu_box(Color("#080c17"), Color("#475c7d"), 10.0))
		button.add_theme_stylebox_override("focus",
			menu_box(Color(0, 0, 0, 0), Color("#b7c0cf"), 0.0))
	leave_button.add_theme_stylebox_override("normal",
		menu_box(Color("#080c17"), Color("#5a4937"), 10.0))
	for field in [url, room_entry]:
		field.custom_minimum_size.y = 44
		field.add_theme_font_size_override("font_size", 20)
		field.add_theme_color_override("font_color", Color("#e4e7ed"))
		field.add_theme_color_override("font_placeholder_color", Color("#b7c0cf"))
		field.add_theme_stylebox_override("normal",
			menu_box(Color("#080c17"), Color("#475c7d"), 10.0))
		field.add_theme_stylebox_override("focus",
			menu_box(Color("#080c17"), Color("#b7c0cf"), 10.0))
	map_view = Control.new()
	map_view.set_script(GraveyardMap)
	canvas.add_child(map_view)
	map_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_view.visible = false

	if not server:
		loss_screen = ShiftFailedScreen.new()
		loss_screen.return_requested.connect(
			func(): begin_room_action("return"))
		loss_screen.leave_requested.connect(
			func(): begin_room_action("leave"))
		add_child(loss_screen)


func begin_room_action(action: String) -> void:
	if server or not pending_action.is_empty():
		return
	if action == "create" or action == "join":
		if admitted:
			return
	elif not admitted:
		return

	pending_action = action
	if peer == null:
		join_server()
	else:
		send_room_request(action)


func send_room_request(action: String) -> void:
	if peer == null or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		leave("Connection unavailable. Try again.")
		return

	request_serial += 1
	pending_request = request_serial
	pending_action = action
	connecting = 10.0
	var code := room_code
	if action == "join":
		code = room_entry.text.strip_edges().to_upper()
	var ready := not bool(roster.get(multiplayer.get_unique_id(), false))
	room_request.rpc_id(1, pending_request, action, code, room_generation, ready)
	refresh_ui()


func join_server() -> void:
	var address := url.text.strip_edges()
	if not address.begins_with("ws://") and not address.begins_with("wss://"):
		notice = "Use a ws:// or wss:// server URL."
		pending_action = ""
		refresh_ui()
		return
	peer = WebSocketMultiplayerPeer.new()
	var result := peer.create_client(address)
	if result != OK:
		peer = null
		pending_action = ""
		notice = "Cannot begin connection: " + error_string(result)
	else:
		multiplayer.multiplayer_peer = peer
		connecting = 10.0
		notice = "Connecting..."
	refresh_ui()


func connected() -> void:
	notice = "Connected; requesting lobby."
	send_room_request(pending_action)


func connection_failed() -> void:
	leave("Connection failed. Check URL, server, port, firewall and TLS.")


func server_lost() -> void:
	leave("Server connection closed. It may be unavailable or have rejected admission.")


func leave(message: String) -> void:
	if peer != null:
		peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	peer = null
	room_code = ""
	room_generation = 0
	room_creator = 0
	pending_request = 0
	pending_action = ""
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
	lobby.connect_peer(id)


@rpc("any_peer", "call_remote", "reliable")
func room_request(request_id: int, action: String, code: String,
		generation: int, ready: bool) -> void:
	if not server:
		return
	lobby.handle_request(multiplayer.get_remote_sender_id(),
		request_id, action, code, generation, ready)


func send_room_reply(id: int, request_id: int, error: String) -> void:
	room_reply.rpc_id(id, request_id, error)


@rpc("authority", "call_remote", "reliable")
func room_reply(request_id: int, error: String) -> void:
	if server or request_id != pending_request:
		return
	pending_request = 0
	pending_action = ""
	connecting = 0.0
	if not error.is_empty():
		notice = error
	refresh_ui()


func peer_disconnected(id: int) -> void:
	if not server:
		return
	lobby.disconnect_peer(id)


func toggle_ready() -> void:
	if admitted and phase == "lobby":
		begin_room_action("ready")


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
	sweeping.reset()
	task_message = ""


@rpc("any_peer", "call_remote", "reliable")
func submit_input(code: String, generation: int,
		movement: Vector2, yaw: float, pitch: float,
		tool: int, light: bool, interact: bool) -> void:
	if not server:
		return
	lobby.accept_input(multiplayer.get_remote_sender_id(), code, generation,
		movement, yaw, pitch, tool, light, interact)


func send_room_snapshot(id: int, state: Dictionary) -> void:
	snapshot.rpc_id(id, state)


@rpc("authority", "call_remote", "reliable")
func snapshot(state: Dictionary) -> void:
	if server:
		return
	if state.is_empty():
		admitted = false
		room_code = ""
		room_generation = 0
		room_creator = 0
		roster.clear()
		clear_players()
		phase = "lobby"
		elapsed = 0.0
		map_view.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		notice = "You left the lobby."
		refresh_ui()
		return

	var previous := phase
	room_code = str(state["code"])
	room_generation = int(state["generation"])
	room_creator = int(state["creator_id"])
	phase = str(state["phase"])
	elapsed = float(state["elapsed"])
	duration = float(state["duration"])
	roster = state["roster"]
	var poses: Dictionary = state["poses"]
	admitted = roster.has(multiplayer.get_unique_id())
	connecting = 0
	notice = str(state["notice"])
	if phase != "running":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if phase == "lobby":
		clear_players()
	else:
		for id in poses:
			if not players.has(id):
				spawn_player(id, id == multiplayer.get_unique_id())
			players[id].receive(poses[id])
	sweeping.receive_state(state["task_state"])
	for id in players:
		var job: Dictionary = sweeping.jobs.get(id, {})
		players[id].is_sweeping = (
			phase == "running"
			and bool(job.get("active", false))
			and not bool(job.get("done", false))
		)
		players[id].sweep_time = float(job.get("seconds", 0.0))
	if previous != phase:
		print("Session state: ", phase)
	refresh_ui()


func _physics_process(delta: float) -> void:
	if server:
		lobby.advance(delta)

	tick += delta
	if tick >= 0.05:
		tick = 0
		if server:
			lobby.broadcast_all()
		elif admitted and phase == "running":
			send_local_input()

	if connecting > 0:
		connecting -= delta
		if connecting <= 0:
			leave("Connection timed out. Check server address, port, firewall and TLS.")

	if not server:
		task_message = ""
		var local_id := multiplayer.get_unique_id()
		if admitted and players.has(local_id) and phase != "lobby":
			task_message = sweeping.describe(local_id, players[local_id])
			if phase != "running":
				task_message += "\nShift ended — sweeping disabled."
		sweeping.set_pickup_visible(
			phase == "running" and players.has(local_id)
			and not players[local_id].has_broom
			and not bool(sweeping.jobs.get(local_id, {}).get("returned", false)))
		if phase != "running" or not admitted:
			map_view.visible = false
		if map_view.visible:
			var job: Dictionary = sweeping.jobs.get(local_id, {})
			var destination := Vector3.ZERO
			if not job.is_empty():
				destination = Sweeping.SITES[int(job["site"])]
			map_view.update_state(
				map_graves, players, local_id,
				destination, not job.is_empty())
		refresh_ui()


func send_local_input() -> void:
	var id := multiplayer.get_unique_id()
	if not players.has(id):
		return
	var player = players[id]
	var movement := Vector2.ZERO
	var interact := false
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and get_window().has_focus():
		movement = Input.get_vector(
			"move_left", "move_right", "move_forward", "move_back")
		interact = Input.is_action_pressed("interact")
	submit_input.rpc_id(1, room_code, room_generation, movement, player.look_yaw,
		player.look_pitch, player.tool, player.lamp_on, interact)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("release_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		map_view.visible = false
	if not admitted or phase != "running":
		return
	var id := multiplayer.get_unique_id()
	if not players.has(id) or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event.is_action_pressed("toggle_map") and not event.is_echo():
		map_view.visible = not map_view.visible
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
	if event.is_action_pressed("equip_broom") and player.has_broom:
		player.tool = 2
	if event.is_action_pressed("toggle_flashlight") and player.tool == 0:
		player.lamp_on = not player.lamp_on
	player.apply_visuals()
	refresh_ui()


func refresh_ui() -> void:
	if server:
		panel.visible = false
		return

	var show_loss := admitted and phase == "ended"
	loss_screen.update_result(
		show_loss, sweeping.completed, Sweeping.TARGET,
		not pending_action.is_empty())
	panel.get_parent().visible = not show_loss
	if show_loss:
		map_view.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	status.text = notice
	var minutes := mini(360, int(elapsed / duration * 360.0))
	var hour := minutes / 60
	var clock := "%d:%02d AM" % [12 if hour == 0 else hour, minutes % 60]
	var equipped := "Flashlight"
	var id := multiplayer.get_unique_id()
	if players.has(id) and players[id].tool == 1:
		equipped = "Shovel"
	if players.has(id) and players[id].tool == 2:
		equipped = "Broom"
	task_hud.text = task_message
	hud.text = "%s | Players: %d/2 | Tool: %s" % [
		clock, roster.size(), equipped]
	if phase == "lobby" and admitted:
		hud.text += " | Ready: %d/2" % roster.values().count(true)
	url.visible = not admitted and peer == null
	room_entry.visible = not admitted
	room_entry.editable = pending_action.is_empty()
	connect_button.visible = not admitted
	connect_button.disabled = not pending_action.is_empty()
	join_button.visible = not admitted
	join_button.disabled = not pending_action.is_empty()
	ready_button.visible = admitted and phase == "lobby"
	ready_button.disabled = not pending_action.is_empty()
	ready_button.text = "Cancel ready" if roster.get(id, false) else "Ready"
	var controlling := admitted and phase == "running" \
		and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	detail.visible = admitted and phase == "running" and not controlling
	menu_title.visible = not controlling
	hud.visible = admitted and phase != "lobby" and not show_loss
	task_hud.visible = admitted and phase != "lobby" and not show_loss
	panel.add_theme_constant_override("separation", 6 if controlling else 12)
	menu_style.set_content_margin_all(12.0 if controlling else 24.0)
	var background := panel.get_parent() as PanelContainer
	var viewport_width := get_viewport().get_visible_rect().size.x
	var width := minf(
		680.0 if controlling else 560.0, maxf(0.0, viewport_width - 32.0))
	background.custom_minimum_size.x = width
	background.size.x = width
	background.position = Vector2(
		16.0 if controlling else maxf(16.0, (viewport_width - width) * 0.5),
		16.0 if controlling else 32.0)
	resume_button.visible = admitted and phase == "running" and not controlling
	leave_button.visible = admitted and not controlling
	leave_button.disabled = not pending_action.is_empty()
	room_info.visible = admitted and not controlling
	room_caption.visible = room_info.visible
	slot_status.visible = admitted and not controlling
	room_info.text = room_code

	var slots := PackedStringArray()
	var members := roster.keys()
	for slot in range(2):
		if slot >= members.size():
			slots.append("Player %d — Waiting for player..." % (slot + 1))
			continue
		var member := int(members[slot])
		var suffix := " (You)" if member == id else ""
		if member == room_creator:
			suffix += " (Creator)"
		slots.append("Player %d%s — %s" % [
			slot + 1, suffix,
			"Ready" if bool(roster[member]) else "Not Ready"])
	slot_status.text = "\n".join(slots)
