# Inventory screen: 30 slot grid + 5 equipment slots + stat panel
extends Control
class_name InventoryScreen

@export var player_path: NodePath

@onready var grid: GridContainer = $Panel/Grid if has_node("Panel/Grid") else null
@onready var stat_label: Label = $Panel/Stats if has_node("Panel/Stats") else null

var player: Node = null
var open: bool = false


func _ready() -> void:
	visible = false
	if player_path != NodePath(""):
		player = get_node_or_null(player_path)
	else:
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
	if player:
		player.inventory.items_changed.connect(_refresh)
		player.stats_recalculated.connect(_refresh)


func _unhandled_input(event: InputEvent) -> void:
	if InputMap.has_action("inventory") and event.is_action_pressed("inventory"):
		toggle()


func toggle() -> void:
	open = not open
	visible = open
	if open:
		_refresh()


func _refresh() -> void:
	if not player or grid == null:
		return
	for child in grid.get_children():
		child.queue_free()
	for i in player.inventory.slots.size():
		var item: ItemResource = player.inventory.slots[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(48, 48)
		if item:
			btn.text = item.item_name.substr(0, 3)
			btn.tooltip_text = item.item_name + "\n" + ItemResource.rarity_name(item.rarity)
			var idx := i
			btn.pressed.connect(func(): _on_slot_clicked(idx))
		grid.add_child(btn)
	if stat_label and player:
		stat_label.text = "Lv %d  XP %d/%d\nATK %.1f  DEF %.1f\nHP %d  Soul %d  Spd %.1f" % [
			player.stats.level,
			int(player.stats.xp),
			int(player.stats.xp_to_next_level()),
			player.stats.attack_damage(),
			player.stats.defense(),
			int(player.stats.max_health()),
			int(player.stats.max_soul()),
			player.stats.move_speed(),
		]


func _on_slot_clicked(slot_index: int) -> void:
	if not player:
		return
	var item: ItemResource = player.inventory.get_item(slot_index)
	if item == null:
		return
	if item.item_type == ItemResource.ItemType.CONSUMABLE:
		player.use_consumable(slot_index)
	else:
		player.equip_item(slot_index)
