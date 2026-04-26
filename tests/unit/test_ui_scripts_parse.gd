## Regression: ensures every script under scripts/ui parses cleanly.
## Previously inventory_screen.gd had a stray `= null` on a const preload that
## made the whole script fail to load, silently disabling the inventory UI.
extends GutTest


const UI_SCRIPTS := [
	"res://scripts/ui/character_select.gd",
	"res://scripts/ui/credits.gd",
	"res://scripts/ui/damage_indicator.gd",
	"res://scripts/ui/enemy_health_bar.gd",
	"res://scripts/ui/game_hud.gd",
	"res://scripts/ui/game_over_screen.gd",
	"res://scripts/ui/health_mana_orbs.gd",
	"res://scripts/ui/inventory_screen.gd",
	"res://scripts/ui/level_up_panel.gd",
	"res://scripts/ui/main_menu.gd",
	"res://scripts/ui/minimap.gd",
	"res://scripts/ui/pause_menu.gd",
	"res://scripts/ui/player_count.gd",
	"res://scripts/ui/settings_menu.gd",
	"res://scripts/ui/skill_hotbar.gd",
	"res://scripts/ui/tutorial_overlay.gd",
]


func test_all_ui_scripts_load():
	for path in UI_SCRIPTS:
		var s = load(path)
		assert_not_null(s, "Failed to load %s" % path)
