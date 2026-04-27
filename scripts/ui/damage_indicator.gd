# DamageIndicator — flashes red vignette on player damage.
extends CanvasLayer
class_name DamageIndicator

var _rect: ColorRect
var _alpha: float = 0.0


func _ready() -> void:
	layer = 50
	_rect = ColorRect.new()
	_rect.color = Color(1.0, 0.0, 0.0, 0.0)
	_rect.anchor_left = 0
	_rect.anchor_top = 0
	_rect.anchor_right = 1
	_rect.anchor_bottom = 1
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)
	# Disable per-frame ticking until we actually flash; re-enabled in the
	# health_changed callback below.
	set_process(false)
	# Wire to all players' health_changed
	for p in get_tree().get_nodes_in_group("player"):
		if p.has_signal("health_changed"):
			var prev: float = p.health
			p.health_changed.connect(func(v):
				if v < prev:
					_alpha = 0.5
					set_process(true)
				prev = v
			)


func _process(delta: float) -> void:
	if _alpha > 0.0:
		_alpha = max(0.0, _alpha - delta * 1.5)
		_rect.color = Color(1.0, 0.0, 0.0, _alpha * 0.4)
		if _alpha == 0.0:
			set_process(false)
