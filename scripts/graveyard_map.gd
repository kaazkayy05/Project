extends Control

const BACKGROUND := Color("#080c17")
const INK := Color("#475c7d")
const PATH := Color("#11345e")
const ACCENT := Color("#786458")

var graves: Array[Vector3] = []
var members: Dictionary = {}
var local_id := 0
var assigned := Vector3.ZERO
var has_assignment := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func update_state(points: Array[Vector3], players: Dictionary,
		own_id: int, target: Vector3, show_target: bool) -> void:
	graves = points
	members.clear()
	for id in players:
		members[id] = [
			players[id].position,
			players[id].look_yaw,
		]
	local_id = own_id
	assigned = target
	has_assignment = show_target
	if visible:
		queue_redraw()


func project_point(point: Vector3, board: Rect2) -> Vector2:
	return board.position + Vector2(
		(point.x + 15.0) / 30.0 * board.size.x,
		(point.z + 16.0) / 32.0 * board.size.y
	)


func world_rect(at: Vector3, world_size: Vector2,
		board: Rect2) -> Rect2:
	var center := project_point(at, board)
	var pixels := world_size * board.size / Vector2(30, 32)
	return Rect2(center - pixels * 0.5, pixels)


func _draw() -> void:
	var viewport_size := get_viewport_rect().size
	var scale_factor := minf(
		1.0, minf(viewport_size.x / 900.0, viewport_size.y / 650.0))
	var board_size := Vector2(330, 352) * scale_factor
	var board := Rect2(
		Vector2(viewport_size.x - board_size.x - 32, 76),
		board_size
	)
	var panel := Rect2(
		board.position - Vector2(16, 48),
		board.size + Vector2(32, 144)
	)
	var font := ThemeDB.fallback_font

	draw_rect(panel, BACKGROUND)
	draw_rect(panel, INK, false, 2.0)
	draw_string(font, panel.position + Vector2(16, 26),
		"CEMETERY MAP — M to close",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 17, INK)

	draw_rect(board, INK, false, 2.0)
	draw_rect(world_rect(Vector3.ZERO, Vector2(3, 30), board), PATH)
	draw_rect(world_rect(Vector3(0, 0, 2), Vector2(27, 2), board), PATH)

	for grave in graves:
		draw_rect(world_rect(grave, Vector2(0.9, 0.5), board), INK)

	draw_rect(world_rect(Vector3(11, 0, -11), Vector2(5, 4), board),
		ACCENT, false, 2.0)
	draw_string(font, project_point(Vector3(7, 0, -14), board),
		"Shed", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, INK)

	draw_line(
		project_point(Vector3(-2, 0, 15.8), board),
		project_point(Vector3(2, 0, 15.8), board),
		ACCENT, 3.0)
	draw_string(font, project_point(Vector3(2.5, 0, 15), board),
		"Gate", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, INK)

	if has_assignment:
		var destination := project_point(assigned, board)
		draw_arc(destination, 10.0, 0, TAU, 24, ACCENT, 2.0)
		draw_string(font, destination + Vector2(-30, -15),
			"Your grave", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, ACCENT)

	for id in members:
		var point: Vector3 = members[id][0]
		var yaw: float = members[id][1]
		var center := project_point(point, board)
		var facing := Vector2(-sin(yaw), -cos(yaw))
		if id == local_id:
			var side := Vector2(-facing.y, facing.x)
			draw_colored_polygon(PackedVector2Array([
				center + facing * 8.0,
				center - facing * 5.0 + side * 5.0,
				center - facing * 5.0 - side * 5.0,
			]), ACCENT)
		else:
			draw_circle(center, 5.0, INK)
		draw_line(center, center + facing * 13.0, INK, 2.0)

	var legend := board.end + Vector2(-board.size.x, 28)
	draw_string(font, legend,
		"Triangle: you   Circle: teammate",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 15, INK)
	draw_string(font, legend + Vector2(0, 23),
		"Ring: your assigned grave",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 15, ACCENT)
	draw_string(font, legend + Vector2(0, 46),
		"Movement and shift clock continue.",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 15, INK)
