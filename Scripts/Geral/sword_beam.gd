extends Node2D

@onready var Area_1: Area2D = $Area1
@onready var Area_2: Area2D = $Area2

var damage = 20
var speed = 400
var direction = Vector2.RIGHT

# --- LISTA DE MEMÓRIA DE ACERTOS ---
# Impede que o projétil dê dano no mesmo inimigo duas vezes
var inimigos_atingidos: Array = [] 

func _ready():
	var notifier = VisibleOnScreenNotifier2D.new()
	add_child(notifier)
	notifier.screen_exited.connect(queue_free)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta * Global.fator_tempo
	
	# Pega corpos de ambas as áreas de colisão
	var corpos_area_1 = Area_1.get_overlapping_bodies()
	var corpos_area_2 = Area_2.get_overlapping_bodies()
	var todos_corpos = corpos_area_1 + corpos_area_2
	
	# Tratamento unificado de colisões
	for body in todos_corpos:
		tratar_colisao(body)

func tratar_colisao(body):
	# Ignora o próprio player
	if body.is_in_group("players"):
		return

	# --- PAREDES E OBSTÁCULOS SÓLIDOS ---
	# Se bater em TileMap ou Parede, destrói o projétil
	if body is TileMap or body is TileMapLayer or body is StaticBody2D or body.is_in_group("parede"):
		queue_free()
		return

	# --- INIMIGOS, BOSS E CRISTAIS ---
	if body.is_in_group("inimigo") or body.is_in_group("boss") or body.is_in_group("cristais"):
		
		# 1. VERIFICAÇÃO DE MEMÓRIA: Já batemos nesse ID específico?
		if body in inimigos_atingidos:
			return # Sai da função, não dá dano de novo
		
		# 2. APLICAÇÃO DE DANO
		if body.has_method("take_damage"):
			body.take_damage(damage)
			
			# 3. ADICIONA À MEMÓRIA
			inimigos_atingidos.append(body)
			
			# Nota: Não chamamos queue_free() aqui para INIMIGOS e BOSS,
			# permitindo que o projétil atravesse ("piercing").
			
			# Exceção (Opcional): Se quiser que cristais bloqueiem o tiro:
			if body.is_in_group("cristais"):
				queue_free()
