extends Node

var menu = 0
var volume = 0.8
var vida = 300
var paused = false
var fator_tempo: float = 1.0
var plataforma = false
var is_in_menu: bool = true

@onready var music_player = $MusicPlayer

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
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
