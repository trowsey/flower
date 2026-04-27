# Enemy health bar (overhead): shows above EnemyBase when below max
extends Sprite3D
class_name EnemyHealthBar

@export var enemy_path: NodePath
@export var bar_width: float = 0.6
@export var bar_height: float = 0.08

var enemy: EnemyBase = null
var _img: Image = null
var _tex: ImageTexture = null


func _ready() -> void:
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	pixel_size = 0.005
	texture_filter = TEXTURE_FILTER_NEAREST
	if enemy_path != NodePath(""):
		enemy = get_node_or_null(enemy_path)
	else:
		enemy = get_parent() as EnemyBase
	_img = Image.create(60, 8, false, Image.FORMAT_RGBA8)
	_tex = ImageTexture.create_from_image(_img)
	texture = _tex
	if enemy:
		enemy.health_changed.connect(_redraw)
	_redraw(enemy.health if enemy else 0.0)


func _redraw(_v: float) -> void:
	if not enemy:
		return
	var pct: float = clamp(enemy.health / max(1.0, enemy.max_health), 0.0, 1.0)
	visible = pct < 1.0 and enemy.alive
	_img.fill(Color(0, 0, 0, 0.7))
	var w: int = int(pct * 60)
	var color := Color.RED
	if enemy.elite:
		color = Color.ORANGE
	for x in w:
		for y in 8:
			_img.set_pixel(x, y, color)
	_tex.update(_img)
