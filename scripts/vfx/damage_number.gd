## DamageNumber — floating label that rises and fades over 0.8 seconds.
extends Label3D

var velocity := Vector3(0, 1.5 / 0.8, 0)
var lifetime: float = 0.8
var elapsed: float = 0.0


func _ready() -> void:
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	pixel_size = 0.005


func _process(delta: float) -> void:
	elapsed += delta
	global_position += velocity * delta
	var t: float = clamp(elapsed / lifetime, 0.0, 1.0)
	modulate.a = 1.0 - t
	if elapsed >= lifetime:
		queue_free()


static func spawn(parent: Node, world_position: Vector3, amount: float, color: Color) -> void:
	var label := DamageNumber.new()
	label.text = str(int(amount))
	label.modulate = color
	label.font_size = 28 if color == Color(1, 0.95, 0.2) else 22
	label.outline_size = 4
	label.outline_modulate = Color.BLACK
	# Random horizontal offset to prevent overlap stacking
	label.global_position = world_position + Vector3(randf_range(-0.3, 0.3), 0.5, randf_range(-0.3, 0.3))
	parent.add_child(label)
