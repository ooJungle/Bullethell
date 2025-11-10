extends Control

func _ready() -> void:
	Global.set_in_menu_state(true)

func _on_play_button_pressed() -> void:
	Global.set_in_menu_state(false)
	get_tree().change_scene_to_file("res://Cenas/Fases/Fase_0.tscn")

func _on_settings_button_pressed() -> void:
	Global.set_in_menu_state(true)
	get_tree().change_scene_to_file("res://Cenas/Menu/SettingsMenu.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
