extends Node

var volume = 0.0
var vida = 300
var paused = false
var fator_tempo: float = 1.0
var plataforma = false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
@onready var music_player = $MusicPlayer

# A sua variável de estado (pode já ter uma parecida)
var is_in_menu: bool = true

# A função "cérebro" que controla a música
func set_in_menu_state(in_menu: bool):
	if in_menu == is_in_menu:
		return

	is_in_menu = in_menu

	if is_in_menu:
		music_player.stop()
	else:
		music_player.play()
