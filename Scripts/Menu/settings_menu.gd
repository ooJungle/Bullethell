extends Control

func _ready() -> void:
	$HSlider.value = Global.volume

func _on_h_slider_value_changed(value: float) -> void:
	Global.volume = value
	
func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Cenas/Menu/MainMenu.tscn")
