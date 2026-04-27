# Minimap: top-down 2D map of explored fog tiles + enemy/player markers
#
# STATUS: Phase 3 stub per docs/specs/world-generation-v2.md. Not yet
# instantiated in the HUD.
extends Control
class_name Minimap

@export var fog_path: NodePath
@export var player_path: NodePath
@export var pixel_per_tile: float = 3.0

var fog: FogOfWar = null
var player: Node3D = null
var _redraw_accum: float = 0.0
const REDRAW_INTERVAL := 0.1  # 10 Hz; visually indistinguishable from 60 Hz


func _ready() -> void:
	if fog_path != NodePath(""):
		fog = get_node_or_null(fog_path)
	if player_path != NodePath(""):
		player = get_node_or_null(player_path)
	else:
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]


func _process(delta: float) -> void:
	_redraw_accum += delta
	if _redraw_accum >= REDRAW_INTERVAL:
		_redraw_accum = 0.0
		queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	# Background
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.5))
	if fog == null or player == null:
		return
	var p_grid: Vector2 = Vector2(player.global_position.x, player.global_position.z)
	for k in fog.explored.keys():
		var coord: Vector2i = k
		var rel := Vector2(float(coord.x), float(coord.y)) * fog.tile_size - p_grid
		var screen_pos := center + rel * pixel_per_tile
		if Rect2(Vector2.ZERO, size).has_point(screen_pos):
			draw_rect(Rect2(screen_pos - Vector2.ONE, Vector2(2, 2)), Color(0.4, 0.4, 0.5, 0.8))
	# Player dot
	draw_circle(center, 3.0, Color.WHITE)
	# Enemies
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var rel := Vector2(e.global_position.x - p_grid.x, e.global_position.z - p_grid.y)
		var sp := center + rel * pixel_per_tile
		if Rect2(Vector2.ZERO, size).has_point(sp):
			var col: Color = Color.RED
			if e.has_method("get") and "elite" in e and e.elite:
				col = Color.ORANGE
			draw_circle(sp, 2.0, col)
