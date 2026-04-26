# Inventory & equipment screen — Diablo-style.
# Built procedurally; instanced as a CanvasLayer child of main.tscn.
# Toggle with `inventory` action (default: I).
extends CanvasLayer

const SLOT_SIZE := 56
const BAG_COLS := 5
const BAG_ROWS := 6

var player: Node = null
var open: bool = false

var _root: PanelContainer
var _bag_grid: GridContainer
var _equip_slots: Dictionary = {}  # ItemType -> Button
var _stat_label: RichTextLabel
var _tooltip: RichTextLabel
var _hovered_btn: Button
const ItemSetScript = preload("res://scripts/items/item_set.gd") = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 50
	_build()
	visible = false
	# Defer attach so player exists
	await get_tree().process_frame
	_attach_first_player()


func _attach_first_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return
	attach_player(players[0])


func attach_player(p: Node) -> void:
	if player == p:
		return
	player = p
	if player.inventory.items_changed.is_connected(_refresh):
		pass
	else:
		player.inventory.items_changed.connect(_refresh)
		player.stats_recalculated.connect(_refresh)
		player.equipment.equipment_changed.connect(func(_a,_b,_c): _refresh())
	_refresh()


func _build() -> void:
	_root = PanelContainer.new()
	_root.set_anchors_preset(Control.PRESET_CENTER)
	_root.position = Vector2(-360, -240)
	_root.custom_minimum_size = Vector2(720, 480)
	add_child(_root)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	_root.add_child(outer)

	var title := Label.new()
	title.text = "INVENTORY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	outer.add_child(title)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	outer.add_child(hbox)

	# --- Equipment column ---
	var eq_col := VBoxContainer.new()
	eq_col.add_theme_constant_override("separation", 4)
	hbox.add_child(eq_col)
	var eq_title := Label.new()
	eq_title.text = "Equipment"
	eq_col.add_child(eq_title)
	var eq_grid := GridContainer.new()
	eq_grid.columns = 2
	eq_grid.add_theme_constant_override("h_separation", 4)
	eq_grid.add_theme_constant_override("v_separation", 4)
	eq_col.add_child(eq_grid)
	for entry in [
		[ItemResource.ItemType.HELMET, "HELM"],
		[ItemResource.ItemType.AMULET, "AMUL"],
		[ItemResource.ItemType.WEAPON, "WEAP"],
		[ItemResource.ItemType.ARMOR, "ARMR"],
		[ItemResource.ItemType.RING, "RING"],
	]:
		var btn := _make_slot_button()
		btn.text = entry[1]
		_equip_slots[entry[0]] = btn
		var slot_type: int = entry[0]
		btn.pressed.connect(func(): _on_equipment_clicked(slot_type))
		btn.mouse_entered.connect(func(): _hovered_btn = btn; _refresh_tooltip())
		btn.mouse_exited.connect(func(): if _hovered_btn == btn: _hovered_btn = null; _refresh_tooltip())
		eq_grid.add_child(btn)
	# Pad to 6 cells (HELM AMUL / WEAP ARMR / RING <pad>)
	var pad := Control.new()
	pad.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	eq_grid.add_child(pad)

	# --- Bag column ---
	var bag_col := VBoxContainer.new()
	bag_col.add_theme_constant_override("separation", 4)
	hbox.add_child(bag_col)
	var bag_title := Label.new()
	bag_title.text = "Bag"
	bag_col.add_child(bag_title)
	_bag_grid = GridContainer.new()
	_bag_grid.columns = BAG_COLS
	_bag_grid.add_theme_constant_override("h_separation", 4)
	_bag_grid.add_theme_constant_override("v_separation", 4)
	bag_col.add_child(_bag_grid)
	for i in BAG_COLS * BAG_ROWS:
		var btn := _make_slot_button()
		var idx := i
		btn.pressed.connect(func(): _on_bag_clicked(idx))
		btn.mouse_entered.connect(func(): _hovered_btn = btn; _refresh_tooltip())
		btn.mouse_exited.connect(func(): if _hovered_btn == btn: _hovered_btn = null; _refresh_tooltip())
		_bag_grid.add_child(btn)

	# --- Stats + tooltip column ---
	var info_col := VBoxContainer.new()
	info_col.add_theme_constant_override("separation", 6)
	hbox.add_child(info_col)
	_stat_label = RichTextLabel.new()
	_stat_label.bbcode_enabled = true
	_stat_label.fit_content = true
	_stat_label.custom_minimum_size = Vector2(220, 160)
	info_col.add_child(_stat_label)
	var sep := HSeparator.new()
	info_col.add_child(sep)
	_tooltip = RichTextLabel.new()
	_tooltip.bbcode_enabled = true
	_tooltip.fit_content = true
	_tooltip.custom_minimum_size = Vector2(220, 200)
	info_col.add_child(_tooltip)

	# --- Footer ---
	var footer := Label.new()
	footer.text = "Click bag item to equip — click equipment to unequip — I to close"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.modulate = Color(0.7, 0.7, 0.75)
	outer.add_child(footer)


func _make_slot_button() -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	b.toggle_mode = false
	return b


func _unhandled_input(event: InputEvent) -> void:
	if InputMap.has_action("inventory") and event.is_action_pressed("inventory"):
		toggle()
		get_viewport().set_input_as_handled()
		return
	# Escape closes only if open (don't steal pause when closed)
	if open and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	open = not open
	visible = open
	if open:
		_refresh()


func _refresh() -> void:
	if not player:
		return
	# Bag
	var bag_buttons := _bag_grid.get_children()
	for i in player.inventory.slots.size():
		if i >= bag_buttons.size():
			break
		var btn: Button = bag_buttons[i]
		var item: ItemResource = player.inventory.slots[i]
		_paint_slot_button(btn, item, true)
	# Equipment
	for slot_type in _equip_slots.keys():
		var btn: Button = _equip_slots[slot_type]
		var item: ItemResource = player.equipment.get_equipped(slot_type)
		_paint_slot_button(btn, item, false, _slot_label(slot_type))
	# Stats
	if _stat_label and player.stats:
		_stat_label.text = "[b]Lv %d[/b]   XP %d/%d\n[color=#ffce42]ATK[/color] %.1f   [color=#7faaff]DEF[/color] %.1f\n[color=#ff7575]HP[/color] %d   [color=#88c8ff]Soul[/color] %d\nSpeed %.1f   AtkSpd %.2f\n\n[b]Stats:[/b] STR %d  VIT %d  SPI %d  AGI %d\nUnspent points: %d" % [
			player.stats.level,
			int(player.stats.xp), int(player.stats.xp_to_next_level()),
			player.stats.attack_damage(), player.stats.defense(),
			int(player.stats.max_health()), int(player.stats.max_soul()),
			player.stats.move_speed(), player.stats.attack_speed(),
			player.stats.strength, player.stats.vitality, player.stats.spirit, player.stats.agility,
			player.stats.stat_points,
		]
	_refresh_tooltip()


func _slot_label(slot_type: int) -> String:
	match slot_type:
		ItemResource.ItemType.HELMET: return "HELM"
		ItemResource.ItemType.AMULET: return "AMUL"
		ItemResource.ItemType.WEAPON: return "WEAP"
		ItemResource.ItemType.ARMOR: return "ARMR"
		ItemResource.ItemType.RING: return "RING"
	return ""


func _paint_slot_button(btn: Button, item: ItemResource, is_bag: bool, fallback: String = "") -> void:
	if item:
		btn.text = item.item_name.left(6) if is_bag else item.item_name.left(5)
		btn.modulate = ItemResource.rarity_color(item.rarity)
		btn.tooltip_text = "%s [%s]" % [item.item_name, ItemResource.rarity_name(item.rarity)]
	else:
		btn.text = "" if is_bag else fallback
		btn.modulate = Color(0.55, 0.55, 0.55) if is_bag else Color(0.45, 0.45, 0.5)
		btn.tooltip_text = ""


func _on_bag_clicked(slot_index: int) -> void:
	if not player:
		return
	var item: ItemResource = player.inventory.get_item(slot_index)
	if item == null:
		return
	if item.item_type == ItemResource.ItemType.CONSUMABLE:
		player.use_consumable(slot_index)
	else:
		player.equip_item(slot_index)


func _on_equipment_clicked(slot_type: int) -> void:
	if not player:
		return
	if player.equipment.get_equipped(slot_type) == null:
		return
	if not player.unequip_item(slot_type):
		_flash_full()


func _flash_full() -> void:
	if _stat_label:
		var orig := _stat_label.modulate
		_stat_label.modulate = Color(1, 0.4, 0.4)
		var tw := create_tween()
		tw.tween_property(_stat_label, "modulate", orig, 0.4)


func _refresh_tooltip() -> void:
	if _tooltip == null:
		return
	if _hovered_btn == null:
		_tooltip.text = "[i]Hover an item to inspect.[/i]"
		return
	var item: ItemResource = _item_for_button(_hovered_btn)
	if item == null:
		_tooltip.text = "[i]Empty slot[/i]"
		return
	var color: Color = ItemResource.rarity_color(item.rarity)
	var hex: String = color.to_html(false)
	var lines: Array = []
	lines.append("[b][color=#%s]%s[/color][/b]" % [hex, item.item_name])
	lines.append("[color=#%s]%s[/color]" % [hex, ItemResource.rarity_name(item.rarity)])
	if item.item_level >= 2:
		lines.append("[color=#aaaaaa]Item Level %d[/color]" % item.item_level)
	if item.description != "":
		lines.append(item.description)
	for k in item.stat_modifiers.keys():
		var v: float = float(item.stat_modifiers[k])
		var sign: String = "+" if v >= 0 else ""
		lines.append("%s%s %s" % [sign, _format_stat_value(k, v), _readable_stat(k)])
	# If hovering a bag item that can be equipped, show diff vs currently equipped
	var is_bag_item: bool = _hovered_bag_item(item)
	if is_bag_item and item.item_type != ItemResource.ItemType.CONSUMABLE and player and player.equipment:
		var equipped: ItemResource = player.equipment.get_equipped(item.item_type)
		if equipped:
			lines.append("[color=#888888]— vs equipped —[/color]")
			var keys_seen: Dictionary = {}
			for k in item.stat_modifiers.keys():
				keys_seen[k] = true
			for k in equipped.stat_modifiers.keys():
				keys_seen[k] = true
			for k in keys_seen.keys():
				var new_v: float = float(item.stat_modifiers.get(k, 0.0))
				var old_v: float = float(equipped.stat_modifiers.get(k, 0.0))
				var diff: float = new_v - old_v
				if abs(diff) < 0.001:
					continue
				var col: String = "#33cc66" if diff > 0 else "#cc4444"
				var sgn: String = "+" if diff > 0 else ""
				lines.append("[color=%s]%s%s %s[/color]" %
					[col, sgn, _format_stat_value(k, diff), _readable_stat(k)])
	if item.set_id != "":
		var set_def = ItemSetScript.by_id(item.set_id)
		if set_def:
			var equipped_count: int = 0
			if player and player.equipment:
				equipped_count = int(player.equipment.get_active_sets().get(item.set_id, 0))
			lines.append("[color=#33cc88]%s (%d/%d)[/color]" %
				[set_def.display_name, equipped_count, set_def.pieces.size()])
			var sorted_thresholds: Array = set_def.bonuses.keys()
			sorted_thresholds.sort()
			for t in sorted_thresholds:
				var active: bool = equipped_count >= int(t)
				var col: String = "#33cc88" if active else "#666666"
				var bonus: Dictionary = set_def.bonuses[t]
				var parts: Array = []
				for bk in bonus.keys():
					var bv: float = float(bonus[bk])
					parts.append("%s%s %s" %
						["+" if bv >= 0 else "",
						 _format_stat_value(bk, bv), _readable_stat(bk)])
				lines.append("[color=%s](%d) %s[/color]" % [col, int(t), ", ".join(parts)])
	_tooltip.text = "\n".join(lines)


func _hovered_bag_item(item: ItemResource) -> bool:
	# Returns true if the hovered button corresponds to a bag slot (not equip slot)
	if _hovered_btn == null or player == null:
		return false
	for slot_type in _equip_slots.keys():
		if _equip_slots[slot_type] == _hovered_btn:
			return false
	return true


func _item_for_button(btn: Button) -> ItemResource:
	if not player:
		return null
	for slot_type in _equip_slots.keys():
		if _equip_slots[slot_type] == btn:
			return player.equipment.get_equipped(slot_type)
	var bag_buttons := _bag_grid.get_children()
	for i in bag_buttons.size():
		if bag_buttons[i] == btn and i < player.inventory.slots.size():
			return player.inventory.slots[i]
	return null


func _format_stat_value(key: String, v: float) -> String:
	if "bonus" in key or "speed" in key or "resist" in key:
		return "%.2f" % v
	return "%.0f" % v


func _readable_stat(key: String) -> String:
	match key:
		"attack_damage_flat": return "Attack Damage"
		"attack_speed_bonus": return "Attack Speed"
		"max_health_flat": return "Max Health"
		"max_soul_flat": return "Max Soul"
		"move_speed_bonus": return "Move Speed"
		"defense_flat": return "Defense"
		"soul_drain_resist": return "Soul Drain Resist"
	return key
