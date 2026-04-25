# GameOverScreen — appears when ALL players have died.
# In single-player mode, shows immediately on death.
# In 2P, only appears when both are dead — gives space for revive (see player.gd).
extends CanvasLayer

@onready var _panel: Control = $Panel
@onready var _retry_btn: Button = $Panel/VBox/Retry
@onready var _menu_btn: Button = $Panel/VBox/QuitToMenu


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel.visible = false
	if _retry_btn:
		_retry_btn.pressed.connect(_retry)
	if _menu_btn:
		_menu_btn.pressed.connect(_to_menu)
	# Defer wiring so players exist in tree
	await get_tree().process_frame
	for p in get_tree().get_nodes_in_group("player"):
		if p.has_signal("player_died"):
			p.player_died.connect(_on_any_player_died)


func _on_any_player_died(_reason: String) -> void:
	# Wait a beat to allow revives in 2P
	await get_tree().create_timer(0.5).timeout
	if _all_dead():
		_show()


func _all_dead() -> bool:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return false
	for p in players:
		if p.has_method("is_alive") and p.is_alive():
			return false
	return true


func _show() -> void:
	_panel.visible = true
	get_tree().paused = true


func _retry() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")
