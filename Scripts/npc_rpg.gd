extends CharacterBody2D

@export var dificuldade: int = 1

var player_na_area: bool = false
var pode_falar: bool = true

func _ready():
	$Area2D.body_entered.connect(func(body): if body.is_in_group("players"): player_na_area = true)
	$Area2D.body_exited.connect(func(body): if body.is_in_group("players"): player_na_area = false)

func _process(delta):
	if player_na_area and Input.is_action_just_pressed("interagir") and pode_falar:
		iniciar_batalha_verbal()

func iniciar_batalha_verbal():
	pode_falar = false
	
	# 1. Chama a Roda (Bullet Hell)
	print("Iniciando Roda de Diálogo...")
	RodaManager.iniciar_roda(dificuldade)
	
	# 2. Espera o minigame acabar e pega o resultado
	var resultado = await RodaManager.roda_finalizada
	
	# 3. Reage ao resultado
	if resultado == "venceu":
		print("NPC: Ok, você me convenceu!")
		# Dialogo.start_dialogue(["Muito bem, aqui está a chave."])
	else:
		print("NPC: Sai daqui, seu fraco!")
		# Dialogo.start_dialogue(["Nem tente falar comigo de novo."])
		# aplicar_knockback_no_player()
	
	# Cooldown para não reativar instantaneamente
	await get_tree().create_timer(1.0).timeout
	pode_falar = true
