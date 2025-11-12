extends Control

func _ready() -> void:
	# Define a posição inicial do slider para o volume guardado
	$HSlider.value = Global.volume

func _on_h_slider_value_changed(value: float) -> void:
	# Chama a nova função global para atualizar o volume em todo o lado
	Global.set_global_volume(value)
	
func _on_back_button_pressed() -> void:
	if Global.menu == 0:
		Global.set_in_menu_state(true)
		get_tree().change_scene_to_file("res://Cenas/Menu/MainMenu.tscn")
	if Global.menu == 1:
		Global.set_in_menu_state(true)
		get_tree().change_scene_to_file("res://Cenas/Menu/PauseMenu.tscn")
