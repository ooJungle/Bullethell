extends CharacterBody2D

@export_multiline var falas_padrao: Array[String] = [
	"",
	""
]

@export_multiline var falas_pos_fase0: Array[String] = [
	"",
	""
]

@export_multiline var falas_pos_fase1: Array[String] = [
	"",
	""
]

@export var portal_alvo: Node2D 

@export var id_da_fase_para_checar: String = "Fase_espaco" 

var player_na_area: bool = false
var pode_falar: bool = true 

var fase_1_concluida = Global.portais_ativos["Fase_espaco"] == false
var fase_2_concluida = Global.portais_ativos["Fase_plat"] == false
var fase_3_concluida = Global.portais_ativos["Fase_RPG"] == false


func _ready():
	$Area2D.body_entered.connect(_on_area_entered)
	$Area2D.body_exited.connect(_on_area_exited)
	if fase_1_concluida and fase_2_concluida and fase_3_concluida:
		queue_free()
		
func _process(delta):
	if player_na_area and Input.is_action_just_pressed("interagir") and pode_falar:
		
		if not Dialogo.is_active:
			iniciar_conversa()

func iniciar_conversa():
	# Bloqueia novas interações
	pode_falar = false
	
	var falas_a_usar = falas_padrao

	var fase_1_concluida = Global.portais_ativos["Fase_espaco"] == false
	var fase_2_concluida = Global.portais_ativos["Fase_plat"] == false
	var fase_3_concluida = Global.portais_ativos["Fase_RPG"] == false


	if fase_1_concluida or fase_2_concluida or fase_3_concluida:
			falas_a_usar = falas_pos_fase0

	if fase_1_concluida and fase_2_concluida or fase_1_concluida and fase_3_concluida or fase_3_concluida and fase_2_concluida:
			falas_a_usar = falas_pos_fase1

	Dialogo.start_dialogue(falas_a_usar)
	
	await Dialogo.finished
	
	if falas_a_usar == falas_padrao:
		ativar_seta_do_player()
	
	await get_tree().create_timer(0.5).timeout
	pode_falar = true

func ativar_seta_do_player():
	if portal_alvo:
		var player = get_tree().get_first_node_in_group("players")
		if player:
			# Certifique-se que seu player tem a função ativar_seta_guia
			player.ativar_seta_guia(portal_alvo.global_position)
	else:
		print("ERRO: Arraste o Portal Alvo para o script do NPC no Inspector!")

func _on_area_entered(body):
	if body.is_in_group("players"):
		player_na_area = true

func _on_area_exited(body):
	if body.is_in_group("players"):
		player_na_area = false
