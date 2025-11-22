extends CharacterBody2D

@export_multiline var falas_do_npc: Array[String] = [
	"Olá! Bem-vindo.",
	"Vá para aquele portal ali para começar sua jornada."
]

@export var portal_alvo: Node2D 

var player_na_area: bool = false
# NOVA VARIÁVEL: Controla se o NPC está "descansando" a voz
var pode_falar: bool = true 

func _ready():
	$Area2D.body_entered.connect(_on_area_entered)
	$Area2D.body_exited.connect(_on_area_exited)

func _process(delta):
	# MUDANÇA AQUI: Adicionamos "and pode_falar" na verificação
	if player_na_area and Input.is_action_just_pressed("interagir") and pode_falar:
		
		if not Dialogo.is_active:
			iniciar_conversa()

func iniciar_conversa():
	# 1. Bloqueia novas interações imediatamente
	pode_falar = false
	
	Dialogo.start_dialogue(falas_do_npc)
	
	await Dialogo.finished
	
	ativar_seta_do_player()
	
	# 2. O PULO DO GATO (COOLDOWN):
	# Espera 0.5 segundos antes de permitir falar de novo.
	# Isso impede que o clique final do diálogo reinicie a conversa.
	await get_tree().create_timer(0.5).timeout
	
	# 3. Libera para falar de novo
	pode_falar = true

func ativar_seta_do_player():
	if portal_alvo:
		var player = get_tree().get_first_node_in_group("players")
		if player:
			player.ativar_seta_guia(portal_alvo.global_position)

func _on_area_entered(body):
	if body.is_in_group("players"):
		player_na_area = true

func _on_area_exited(body):
	if body.is_in_group("players"):
		player_na_area = false
