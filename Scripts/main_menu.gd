extends Control

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Cenas/Fase_0.tscn")

func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Cenas/SettingsMenu.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
