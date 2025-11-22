extends Node


var menu = 0
var volume = 0.3
var dialogo_final_mostrado: bool = false
var vida = 300
var paused = false
var fator_tempo: float = 1.0
var plataforma = false
var is_in_menu: bool = true

var portais_ativos = {
	"Fase_espaco": true,
	"Fase_plat": true, 
	"Fase_RPG": true
}

@onready var music_player = $MusicPlayer

func _ready() -> void:
	get_tree().get_root().transparent_bg = true
	get_tree().get_root().set_transparent_background(true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true, 0)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true, 0)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	# Aplica o volume inicial (0.5) convertendo para dB
	set_global_volume(volume)

func set_in_menu_state(in_menu: bool):
	if in_menu == is_in_menu:
		return
	
	is_in_menu = in_menu
	
	if is_in_menu:
		music_player.stop()
	else:
		music_player.play()

func set_global_volume(valor_linear: float):
	volume = valor_linear
	var volume_em_db = linear_to_db(volume)
	
	if is_instance_valid(music_player):
		music_player.volume_db = volume_em_db
