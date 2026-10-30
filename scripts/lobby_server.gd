extends Node

signal snapshot_ready(receiver: int, state: Dictionary)
signal reply_ready(receiver: int, request_id: int, error: String)

const RoomSession = preload("res://scripts/room_session.gd")
const CODE_ALPHABET := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

var duration := 720.0
var rooms: Dictionary = {}
var peer_rooms: Dictionary = {}
var last_requests: Dictionary = {}
var issued_codes: Dictionary = {}
var crypto := Crypto.new()


func connect_peer(id: int) -> void:
	last_requests[id] = 0


func disconnect_peer(id: int) -> void:
	remove_member(id)
	last_requests.erase(id)


func handle_request(id: int, request_id: int, action: String,
		code: String, generation: int, ready: bool) -> void:
	if not last_requests.has(id):
		return
	if request_id <= int(last_requests[id]):
		reply_ready.emit(id, request_id, "Outdated request ignored.")
		return

	last_requests[id] = request_id

	var error := ""
	if code.length() > 64:
		error = "Invalid room code."
	else:
		error = execute_request(
			id, action, code.strip_edges().to_upper(), generation, ready)

	if not error.is_empty() and peer_rooms.has(id):
		var current_code := str(peer_rooms[id])
		snapshot_ready.emit(id, room_state(current_code))

	reply_ready.emit(id, request_id, error)


func execute_request(id: int, action: String, code: String,
		generation: int, ready: bool) -> String:
	if action == "create" or action == "join":
		if peer_rooms.has(id):
			return "Leave your current lobby before entering another."

		if action == "create":
			code = new_code()
			if code.is_empty():
				return "Could not create a room. Try again."

			var session := RoomSession.new()
			session.name = "Room_" + code
			session.duration = duration
			rooms[code] = session
			issued_codes[code] = true
			session.state_changed.connect(broadcast_room.bind(code))
			add_child(session)
		else:
			if not valid_code(code) or not rooms.has(code):
				return "Invalid or expired room code."

			var existing: RoomSession = rooms[code]
			if existing.roster.size() >= 2:
				return "That room is full."
			if existing.phase != "lobby":
				return "That room's shift is already in progress."

		# Membership is assigned before add_member emits its snapshot.
		peer_rooms[id] = code
		var session: RoomSession = rooms[code]
		var error := session.add_member(id)
		if not error.is_empty():
			peer_rooms.erase(id)
			return error
		return ""

	var session := member_room(id, code, generation)
	if session == null:
		return "Lobby state changed. Check the latest update and try again."

	match action:
		"ready":
			if session.phase != "lobby":
				return "Readiness can only change in the lobby."
			session.set_member_ready(id, ready)
		"return":
			if session.phase != "ended":
				return "The shift has not ended."
			session.reset_to_lobby("Returned to lobby. Both players must ready up.")
			broadcast_room(code)
		"leave":
			remove_member(id)
			snapshot_ready.emit(id, {})
		_:
			return "Unknown lobby request."

	return ""


func member_room(id: int, code: String, generation: int) -> RoomSession:
	if str(peer_rooms.get(id, "")) != code or not rooms.has(code):
		return null
	var session: RoomSession = rooms[code]
	if session.generation != generation or not session.roster.has(id):
		return null
	return session


func accept_input(id: int, code: String, generation: int,
		movement: Vector2, yaw: float, pitch: float,
		tool: int, light: bool, interact: bool) -> void:
	var session := member_room(id, code, generation)
	if session == null:
		return
	session.accept_input(id, movement, yaw, pitch, tool, light, interact)


func remove_member(id: int) -> void:
	if not peer_rooms.has(id):
		return

	var code := str(peer_rooms[id])
	peer_rooms.erase(id)

	var session: RoomSession = rooms[code]
	session.remove_member(id)
	if session.roster.is_empty():
		rooms.erase(code)
		remove_child(session)
		session.queue_free()


func advance(delta: float) -> void:
	for session in rooms.values():
		session.advance(delta)


func broadcast_all() -> void:
	for code in rooms:
		broadcast_room(code)


func broadcast_room(code: String) -> void:
	if not rooms.has(code):
		return

	var state := room_state(code)
	for id in state["roster"]:
		snapshot_ready.emit(id, state)


func room_state(code: String) -> Dictionary:
	var session: RoomSession = rooms[code]
	var state := session.export_snapshot()
	state["code"] = code
	state["generation"] = session.generation
	state["creator_id"] = session.creator_id
	return state


func valid_code(code: String) -> bool:
	if code.length() != 6:
		return false
	for index in range(code.length()):
		if not CODE_ALPHABET.contains(code.substr(index, 1)):
			return false
	return true


func new_code() -> String:
	for attempt in range(64):
		var bytes := crypto.generate_random_bytes(6)
		if bytes.size() != 6:
			return ""

		var code := ""
		for value in bytes:
			code += CODE_ALPHABET.substr(
				int(value) % CODE_ALPHABET.length(), 1)

		# Avoid reusing a code during this server's lifetime.
		if not issued_codes.has(code):
			return code

	return ""
