extends Control

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Cenas/Fases/fase_teste.tscn")

func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Cenas/Menu/SettingsMenu.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
