extends CharacterBody2D

@export var dificuldade: int = 1

# Variáveis de controle
var player_na_area: bool = false
var pode_falar: bool = true
var inimigos_restantes: int = 0 # Começa em 0 para permitir a primeira conversa

func _ready():
	$Area2D.body_entered.connect(_on_area_entered)
	$Area2D.body_exited.connect(_on_area_exited)
	
	# Conecta o sinal global de morte
	Global.inimigo_morreu.connect(_on_inimigo_morreu)

func _process(_delta):
	# Verifica se o player está perto, apertou o botão, e se NÃO TEM inimigos vivos da missão
	if player_na_area and Input.is_action_just_pressed("interagir") and pode_falar and inimigos_restantes <= 0:
		iniciar_conversa()

func iniciar_conversa():
	pode_falar = false
	print("Iniciando interação com a Roda...")
	
	RodaManager.iniciar_roda(dificuldade)
	
	var resultado = await RodaManager.roda_finalizada
	print("O Jogador escolheu: ", resultado)
	
	var quantidade_inimigos = 0
	
	match resultado:
		"Agressivo": 
			quantidade_inimigos = 20 
		"Neutro":    
			quantidade_inimigos = 8  
		"Defensivo": 
			quantidade_inimigos = 3 
	
	# --- A CORREÇÃO ESTÁ AQUI ---
	# Atualiza a variável de bloqueio com a quantidade escolhida
	inimigos_restantes = quantidade_inimigos
	print("NPC Bloqueado! Faltam matar: ", inimigos_restantes)
	# ----------------------------

	var fase_atual = get_tree().current_scene
	if fase_atual.has_method("spawnar_onda_por_escolha"):
		fase_atual.spawnar_onda_por_escolha(quantidade_inimigos)
	
	await get_tree().create_timer(1.0).timeout
	pode_falar = true
	# Agora, mesmo com pode_falar = true, o 'if' do _process vai bloquear 
	# porque inimigos_restantes é maior que 0.

func _on_inimigo_morreu():
	# Só desconta se o NPC estiver esperando mortes
	if inimigos_restantes > 0:
		inimigos_restantes -= 1
		print("Inimigo abatido. Restam: ", inimigos_restantes)
		
		if inimigos_restantes <= 0:
			print("Todos os inimigos derrotados! NPC liberado.")
			# Opcional: Tocar som ou mudar sprite do NPC aqui

func _on_area_entered(body):
	if body.is_in_group("players"): 
		player_na_area = true

func _on_area_exited(body):
	if body.is_in_group("players"):
		player_na_area = false
