extends Control
var master_bus_index: int
var musica_bus_index: int
var sfx_bus_index: int
@onready var musica: HSlider = $VBoxContainer/musica
@onready var sfx: HSlider = $VBoxContainer/sfx

func _ready() -> void:
	musica_bus_index = AudioServer.get_bus_index("musica") 
	sfx_bus_index = AudioServer.get_bus_index("sfx")
	if musica:
		musica.value = db_to_linear(AudioServer.get_bus_volume_db(musica_bus_index))
		
	if sfx:
		sfx.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_bus_index))
	# Define a posição inicial do slider para o volume guardado
	
	$VBoxContainer/HSlider.value = Global.volume

func _on_h_slider_value_changed(value: float) -> void:
	# Chama a nova função global para atualizar o volume em todo o lado
	Global.set_global_volume(value)
	
func _on_back_button_pressed() -> void:
	Transicao.transition()
	await Transicao.on_transition_finished
	if Global.menu == 0:
		get_tree().change_scene_to_file("res://Cenas/Menu/MainMenu.tscn")
	if Global.menu == 1:
		queue_free()

func _on_musica_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(musica_bus_index, linear_to_db(value))

func _on_sfx_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(value))
