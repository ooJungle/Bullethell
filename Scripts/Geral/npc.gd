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

# --- REFERÊNCIA AO SPRITE ---
# Verifique se o nome do nó na sua cena é "AnimatedSprite2D" ou ajuste aqui
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var player_na_area: bool = false
var pode_falar: bool = true 

# Estas variáveis pegam o valor assim que o jogo começa
var fase_1_concluida = Global.portais_ativos["Fase_espaco"] == false
var fase_2_concluida = Global.portais_ativos["Fase_plat"] == false
var fase_3_concluida = Global.portais_ativos["Fase_RPG"] == false

func _ready():
	$Area2D.body_entered.connect(_on_area_entered)
	$Area2D.body_exited.connect(_on_area_exited)
	
	# Inicia a animação de parado (respirando)
	if sprite:
		sprite.play("idle")
	
	# Se todas as fases foram concluídas, o NPC some
	if fase_1_concluida and fase_2_concluida and fase_3_concluida:
		queue_free()
		
func _process(_delta):
	if player_na_area and Input.is_action_just_pressed("interagir") and pode_falar:
		if not Dialogo.is_active:
			iniciar_conversa()

func iniciar_conversa():
	# Bloqueia novas interações
	pode_falar = false
	
	# --- INICIA ANIMAÇÃO DE FALAR ---
	if sprite:
		sprite.play("falando")
	
	var falas_a_usar = falas_padrao

	# Atualiza o estado das fases para saber o progresso atual
	var f1 = Global.portais_ativos["Fase_espaco"] == false
	var f2 = Global.portais_ativos["Fase_plat"] == false
	var f3 = Global.portais_ativos["Fase_RPG"] == false

	# Lógica de Progresso:
	# Se completou pelo menos 1 fase
	if f1 or f2 or f3:
		falas_a_usar = falas_pos_fase0

	# Se completou pelo menos 2 fases (sobreescreve a anterior)
	if (f1 and f2) or (f1 and f3) or (f3 and f2):
		falas_a_usar = falas_pos_fase1

	Dialogo.start_dialogue(falas_a_usar)
	
	await Dialogo.finished
	
	# --- VOLTA PARA ANIMAÇÃO DE PARADO ---
	if sprite:
		sprite.play("idle")
	
	# Só ativa a seta se estiver nas falas iniciais (opcional, depende da sua lógica)
	if falas_a_usar == falas_padrao:
		ativar_seta_do_player()
	
	await get_tree().create_timer(0.5).timeout
	pode_falar = true

func ativar_seta_do_player():
	if portal_alvo:
		var player = get_tree().get_first_node_in_group("players")
		if player:
			player.ativar_seta_guia(portal_alvo.global_position)
	else:
		print("ERRO: Arraste o Portal Alvo para o script do NPC no Inspector!")

func _on_area_entered(body):
	if body.is_in_group("players"):
		player_na_area = true

func _on_area_exited(body):
	if body.is_in_group("players"):
		player_na_area = false
