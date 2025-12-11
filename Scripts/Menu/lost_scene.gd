extends Node

func _ready() -> void:
	Global.is_in_menu
func _on_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Cenas/Menu/MainMenu.tscn")
