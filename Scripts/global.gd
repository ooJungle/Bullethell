extends Node

var volume = 0.0
var vida = 300
var paused = false
var fator_tempo: float = 1.0
var plataforma = false

signal tomou_dano

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	

func Tomou_ano():
	tomou_dano.emit()
