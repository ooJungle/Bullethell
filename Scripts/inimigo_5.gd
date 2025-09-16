extends CharacterBody2D

@export var velocidade = 150.0
@export var player: Node2D
@export var nitidez_curva = 2.0 # Quão rápido o inimigo muda de direção. Valores maiores = curvas mais fechadas.

@onready var sprite: AnimatedSprite2D = $sprite
@onready var raycasts: Array[RayCast2D] = [
	$RayCast0, $RayCast1, $RayCast2, $RayCast3, 
	$RayCast4, $RayCast5, $RayCast6, $RayCast7
]

const obj_tiro_azul = preload("res://Cenas/tiro_azul.tscn")
var timer = 0.0

# Knockback
var knockback = false
var tempo_knockback = 0.0

# --- Lógica da IA de Context Steering ---
# 8 direções, começando da direita (Leste) e girando no sentido anti-horário.
var direcoes = [
	Vector2(1, 0),    # Direita
	Vector2(1, -1).normalized(),  # Cima-Direita
	Vector2(0, -1),   # Cima
	Vector2(-1, -1).normalized(), # Cima-Esquerda
	Vector2(-1, 0),   # Esquerda
	Vector2(-1, 1).normalized(),  # Baixo-Esquerda
	Vector2(0, 1),    # Baixo
	Vector2(1, 1).normalized()    # Baixo-Direita
]
const PERIGO_VALOR = 5.0 # Peso alto para direções perigosas (com obstáculos)

func _ready() -> void:
	add_to_group("enemies")

func shoot():
	if timer >= 1.2:
		var new_bullet = obj_tiro_azul.instantiate()
		var direction = (player.position - position).normalized()
		
		new_bullet.player = player
		new_bullet.position = position
		new_bullet.velocity = direction * velocidade
		get_parent().add_child(new_bullet)
		timer = 0.0

# Função principal da IA que decide a melhor direção
func _get_context_steering_direction() -> Vector2:
	if not is_instance_valid(player):
		return Vector2.ZERO

	# Arrays para guardar os pesos de cada direção
	var interest = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	var danger = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	
	# --- Passo 1: Calcular Incentivos (Interest) ---
	# O principal incentivo é ir em direção ao jogador.
	var direcao_para_player = (player.position - position).normalized()
	for i in direcoes.size():
		# O produto escalar (dot product) nos diz o quão alinhada uma direção está com a direção do player.
		# O resultado é de 1 (mesma direção) a -1 (direção oposta).
		var dot_product = direcoes[i].dot(direcao_para_player)
		interest[i] = max(0.0, dot_product) # Usamos max(0.0) para ignorar direções que apontam para longe do player.

	# --- Passo 2: Calcular Perigos (Danger) ---
	# Verificamos cada raycast para detectar obstáculos.
	for i in raycasts.size():
		if raycasts[i].is_colliding():
			danger[i] = PERIGO_VALOR
	
	# --- Passo 3: Criar o Mapa de Contexto e Decidir ---
	var context_map = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	for i in direcoes.size():
		context_map[i] = interest[i] - danger[i]

	# Encontramos a melhor direção (aquela com o maior valor no mapa de contexto).
	var melhor_direcao = Vector2.ZERO
	var max_valor = -INF # Inicia com um valor infinitamente baixo
	for i in direcoes.size():
		if context_map[i] > max_valor:
			max_valor = context_map[i]
			melhor_direcao = direcoes[i]
			
	return melhor_direcao

func _physics_process(delta: float) -> void:
	timer += delta
	
	# Processa o estado de knockback primeiro
	if not knockback:
		var nearby = get_tree().get_nodes_in_group("players")
		for other in nearby:
			if other == self:
				continue
			var dist = (other.position - position)
			if dist.length() <= 20:
				knockback = true
				tempo_knockback = 0.0
				break  # sai do loop para não reativar no mesmo frame

	# processa o estado de knockback
	if knockback:
		tempo_knockback += delta
		if tempo_knockback > 0.2:
			position = Vector2.ZERO
		if tempo_knockback >= 2.0:
			knockback = false
		else:
			position -= 7*(player.position - position).normalized()

		return # Pula o resto da lógica se estiver em knockback

	move_and_slide()

	# Lógica de movimento principal
	var direcao_desejada = _get_context_steering_direction()
	var velocidade_desejada = direcao_desejada * velocidade
	
	# Suaviza o movimento usando interpolação linear (lerp)
	# Isso cria o efeito de "steering" (direção) em vez de uma mudança de direção instantânea.
	velocity = velocity.lerp(velocidade_desejada, nitidez_curva * delta)
	
	# Checa colisão com outros inimigos/player para iniciar knockback
	move_and_slide()

	# --- Lógica de Animação e Visual ---
	# Flip do sprite
	if velocity.x > 0:
		sprite.flip_h = false
	elif velocity.x < 0:
		sprite.flip_h = true
	
	# Animação
	if velocity.length() > 0.1: # Pequena margem para evitar animação de andar quando parado
		sprite.play("Walking")
	else:
		sprite.play("Idle")
	
	# Atirar
	if is_instance_valid(player) and (player.position - position).length() < 500:
		shoot()
