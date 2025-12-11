extends Node

const espaco = preload("res://Cenas/Fases/Fase_espaco.tscn")
const plat = preload("res://Cenas/Fases/Fase_plat.tscn")
const RPG = preload("res://Cenas/Fases/Fase_RPG.tscn")
const SAVE_PATH = "user://save_game.json"

var menu = 0
var volume = 0.3
var dialogo_final_mostrado: bool = false
var vida = 12
var paused = false
var fator_tempo: float = 1.0
var plataforma = false
var is_in_menu: bool = true
var zerou = false
var primeira_vez = true

var portais_ativos = {
	"Fase_espaco": false,
	"Fase_plat": false,
	"Fase_RPG": false
}

@onready var music_player = $MusicPlayer
@onready var musica_timer: Timer = $Timer

signal inimigo_morreu
signal boss_final_morreu
signal vida_mudou(nova_vida)

func _ready() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		novo_jogo()
		
	get_tree().get_root().transparent_bg = true
	get_tree().get_root().set_transparent_background(true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true, 0)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true, 0)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	set_global_volume(volume)
	carregar()
	if zerou == true:
		get_tree().quit()

func atualizar_hud_vida(valor):
	vida = valor
	emit_signal("vida_mudou", vida)
	
func alternar_pause_musica(pausado: bool):
	music_player.stream_paused = pausado
	
func set_in_menu_state(in_menu: bool):
	if in_menu == is_in_menu:
		return
	
	is_in_menu = in_menu
	
	if is_in_menu :
		music_player.stop()
		musica_timer.stop()
	else:
		timer()

func timer():
	musica_timer.start(2.0)

func set_global_volume(valor_linear: float):
	volume = valor_linear
	var volume_em_db = linear_to_db(volume)
	
	if is_instance_valid(music_player):
		music_player.volume_db = volume_em_db

func novo_jogo():
	zerou = false
	save()
	carregar()

func save():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	var save_dict = {
		"zerou": zerou
	}
	
	var json_string = JSON.stringify(save_dict, "\t")
	file.store_string(json_string)
	file.close()
	
func carregar():
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var json_string = file.get_as_text()
	file.close()
	
	var parse_result = JSON.parse_string(json_string)
	
	if parse_result == null:
		return
	var data = parse_result
	
	zerou = data.get("zerou", false)
func boss_morreu():
	boss_final_morreu.emit()

func creditos():
	var caminho_base = OS.get_executable_path().get_base_dir()
	var caminho_arquivo = caminho_base.path_join("creditos.txt")
	var arquivo = FileAccess.open(caminho_arquivo, FileAccess.WRITE)
	
	if arquivo:
		arquivo.store_string("OBRIGADO POR JOGAR!\n")
		arquivo.store_string("-------------------\n")
		arquivo.store_string("Por: João, Caio, Caio e Gusta\n")
		arquivo.close()
		print("Arquivo criado em: ", caminho_arquivo)
		OS.shell_open(caminho_arquivo)
	else:
		printerr("Erro ao tentar criar o arquivo. Verifique permissões.")
	


func _on_timer_timeout() -> void:
	primeira_vez = false
	musica_timer.stop()
	music_player.play()
