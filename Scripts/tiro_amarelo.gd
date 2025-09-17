extends CharacterBody2D

# --- Variáveis de Movimento e Combate ---
@export var velocidade = 100.0
@export var player: Node2D
@export var nitidez_curva = 5.0
@export var forca_knockback = 450.0

# --- Nós Filhos ---
@onready var sprite: AnimatedSprite2D = $sprite
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var raycasts: Array[RayCast2D] = [
	$RayCast0, $RayCast1, $RayCast2, $RayCast3, 
	$RayCast4, $RayCast5, $RayCast6, $RayCast7
]
@onready var area_deteccao: Area2D = $Area2D
@onready var los_raycast: RayCast2D = $LOS_RayCast # "Olhos" da IA
@onready var perception_timer: Timer = $PerceptionTimer

# --- Disparos ---
const obj_tiro_azul = preload("res://Cenas/tiro_azul.tscn")
var timer = 0.0

# --- Knockback ---
var knockback = false
var tempo_knockback = 0.0

# --- Lógica de Context Steering ---
var direcoes = [
	Vector2(1, 0), Vector2(1, -1).normalized(), Vector2(0, -1), Vector2(-1, -1).normalized(), 
	Vector2(-1, 0), Vector2(-1, 1).normalized(), Vector2(0, 1), Vector2(1, 1).normalized()
]
const PERIGO_VALOR = 10.0

# --- LÓGICA NOVA: MÁQUINA DE ESTADOS E MEMÓRIA ---
enum State { PERSEGUINDO, PROCURANDO }
var current_state = State.PROCURANDO

var player_last_known_position: Vector2
var tilemap: TileMapLayer # Precisamos de uma referência ao tilemap

# O Mapa de Cheiro (Scent Map)
var scent_map: Dictionary = {} # Usamos um dicionário para guardar {Vector2i: forca_do_cheiro}
const FORCA_MAX_CHEIRO = 100.0
const DECAIMENTO_CHEIRO = 5.0 # Quão rápido o cheiro desaparece

func _ready() -> void:
	add_to_group("enemies")
	# Encontra o tilemap na cena principal (ajuste se necessário)
	tilemap = get_tree().get_first_node_in_group("level_tilemap")
	
	# Conectamos o sinal do timer à função de perceção
	perception_timer.timeout.connect(_on_perception_timer_timeout)


# ================================================================
# --- LÓGICA DE PERCEÇÃO E MEMÓRIA (O CÉREBRO DA IA) ---
# ================================================================

# Esta função é chamada a cada 0.2 segundos pelo Timer
func _on_perception_timer_timeout():
	update_scent_map()
	
	var can_see_player = check_line_of_sight()
	
	if can_see_player:
		# Se vemos o jogador, atualizamos a sua última posição conhecida
		player_last_known_position = player.global_position
		# Entramos no estado de perseguição
		current_state = State.PERSEGUINDO
		# E deixamos um "cheiro" forte no local
		var player_tile = tilemap.local_to_map(player.global_position)
		lay_scent(player_tile)
	else:
		# Se não vemos o jogador, entramos no estado de procura
		current_state = State.PROCURANDO

func check_line_of_sight() -> bool:
	if not is_instance_valid(player):
		return false
		
	# Apontamos o raio para a posição relativa do jogador
	los_raycast.target_position = to_local(player.global_position)
	los_raycast.force_raycast_update()
	
	# Se o raio NÃO colidiu com uma parede, temos linha de visão!
	return not los_raycast.is_colliding()

func lay_scent(tile_pos: Vector2i):
	# Coloca o cheiro máximo no tile e um cheiro mais fraco nos vizinhos (propagação simples)
	scent_map[tile_pos] = FORCA_MAX_CHEIRO
	for x in range(-1, 2):
		for y in range(-1, 2):
			if x == 0 and y == 0: continue
			var neighbor_pos = tile_pos + Vector2i(x, y)
			# Só adiciona cheiro vizinho se não houver já um cheiro mais forte lá
			if not scent_map.has(neighbor_pos) or scent_map[neighbor_pos] < FORCA_MAX_CHEIRO / 2:
				scent_map[neighbor_pos] = FORCA_MAX_CHEIRO / 2

func update_scent_map():
	var tiles_to_erase = []
	for tile in scent_map:
		scent_map[tile] -= DECAIMENTO_CHEIRO
		if scent_map[tile] <= 0:
			tiles_to_erase.append(tile)
	
	for tile in tiles_to_erase:
		scent_map.erase(tile)

func get_best_scent_direction() -> Vector2:
	var best_scent_pos = global_position
	var max_scent = 0.0
	
	var current_tile = tilemap.local_to_map(global_position)
	
	# Verifica os 8 tiles vizinhos
	for x in range(-1, 2):
		for y in range(-1, 2):
			if x == 0 and y == 0: continue
			var neighbor_tile = current_tile + Vector2i(x, y)
			if scent_map.has(neighbor_tile) and scent_map[neighbor_tile] > max_scent:
				max_scent = scent_map[neighbor_tile]
				best_scent_pos = tilemap.map_to_local(neighbor_tile)
	
	return (best_scent_pos - global_position).normalized()


# ================================================================
# --- LÓGICA DE MOVIMENTO E AÇÃO (O CORPO DA IA) ---
# ================================================================

func _physics_process(delta: float) -> void:
	timer += delta
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		move_and_slide(); return

	# O Knockback tem prioridade máxima sobre todos os estados
	if knockback:
		tempo_knockback += delta
		if tempo_knockback >= 0.4:
			knockback = false
		velocity = velocity.lerp(Vector2.ZERO, delta * 5.0)
		move_and_slide(); return

	var direcao_alvo = Vector2.ZERO

	# A Máquina de Estados decide qual é o alvo
	match current_state:
		State.PERSEGUINDO:
			# No estado de perseguição, o alvo é a última posição conhecida do jogador
			navigation_agent.target_position = player_last_known_position
			direcao_alvo = (navigation_agent.get_next_path_position() - global_position).normalized()
		
		State.PROCURANDO:
			# No estado de procura, o alvo é a direção com o "cheiro" mais forte
			var direcao_cheiro = get_best_scent_direction()
			if direcao_cheiro != Vector2.ZERO:
				direcao_alvo = direcao_cheiro
			else:
				# Se não há cheiro, o inimigo para (ou poderia patrulhar)
				direcao_alvo = Vector2.ZERO

	# O resto do código de movimento é o mesmo, mas usa o 'direcao_alvo' decidido pela máquina de estados
	if direcao_alvo.length() > 0:
		var direcao_desejada = _get_context_steering_direction(direcao_alvo)
		var velocidade_desejada = direcao_desejada * velocidade
		velocity = velocity.lerp(velocidade_desejada, nitidez_curva * delta)
	else:
		velocity = velocity.lerp(Vector2.ZERO, nitidez_curva * delta)

	move_and_slide()
	
	if not knockback:
		var corpos_sobrepostos = area_deteccao.get_overlapping_bodies()
		for corpo in corpos_sobrepostos:
			if corpo.is_in_group("players"):
				var direcao_afastar = corpo.global_position.direction_to(global_position)
				if direcao_afastar == Vector2.ZERO: direcao_afastar = Vector2.UP
				global_position += direcao_afastar * 1.0
				break
	
	update_animation_and_flip()
	
	# Só atira se estiver no estado de perseguição
	if current_state == State.PERSEGUINDO and (player.global_position - global_position).length() < 500:
		shoot()


# --- Funções de Suporte (sem grandes alterações) ---
func _get_context_steering_direction(direcao_alvo: Vector2) -> Vector2:
	# ... (código inalterado) ...
func update_animation_and_flip():
	# ... (código inalterado) ...
func aplicar_knockback(direcao: Vector2):
	# ... (código inalterado) ...
func _on_area_2d_body_entered(body: Node2D) -> void:
	# ... (código inalterado) ...
func shoot():
	# ... (código inalterado) ...
