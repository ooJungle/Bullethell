extends Node

func _on_retry_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Cenas/Fases/fase_teste.tscn")

func _on_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Cenas/Menu/MainMenu.tscn")
