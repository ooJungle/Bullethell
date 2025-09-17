extends CharacterBody2D

# --- Variáveis de Movimento e Combate ---
@export var velocidade = 100.0
@export var player: Node2D
@export var nitidez_curva = 5.0
@export var forca_knockback = 450.0
@export var raio_proximidade = 250.0 # Distância a que o inimigo "ouve" o jogador

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
const obj_tiro_azul = preload("res://Cenas/Projeteis/tiro_azul.tscn")
var timer = 0.0

# --- Knockback ---
var knockback = false
var tempo_knockback = 0.0

# --- Lógica de Context Steering ---
var direcoes = [
	Vector2(1, 0), Vector2(1, -1).normalized(), Vector2(0, -1), Vector2(-1, -1).normalized(), 
	Vector2(-1, 0), Vector2(-1, 1).normalized(), Vector2(0, 1), Vector2(1, 1).normalized()
]
const PERIGO_VALOR = 6.0
const BONUS_DIRECAO_GPS = 4.0

# --- MÁQUINA DE ESTADOS E MEMÓRIA ---
enum State { PERSEGUINDO, PROCURANDO }
var current_state = State.PROCURANDO

var player_last_known_position: Vector2
var tilemap: TileMapLayer

# O Mapa de Cheiro (Scent Map)
var scent_map: Dictionary = {}
const FORCA_MAX_CHEIRO = 100.0
const DECAIMENTO_CHEIRO = 5.0

func _ready() -> void:
	add_to_group("enemies")
	tilemap = get_tree().get_first_node_in_group("level_tilemap")
	player_last_known_position = global_position
	perception_timer.timeout.connect(_on_perception_timer_timeout)


# ================================================================
# --- LÓGICA DE PERCEÇÃO E MEMÓRIA ---
# ================================================================
func _on_perception_timer_timeout():
	update_scent_map()
	
	if not is_instance_valid(player):
		current_state = State.PROCURANDO
		return

	var can_see_player = check_line_of_sight()
	
	if can_see_player:
		player_last_known_position = player.global_position
		current_state = State.PERSEGUINDO
		var player_tile = tilemap.local_to_map(player.global_position)
		lay_scent(player_tile)
	elif global_position.distance_to(player.global_position) < raio_proximidade:
		player_last_known_position = player.global_position
		var player_tile = tilemap.local_to_map(player.global_position)
		lay_scent(player_tile)
		current_state = State.PROCURANDO
	else:
		current_state = State.PROCURANDO

func check_line_of_sight() -> bool:
	if not is_instance_valid(player):
		return false
		
	los_raycast.target_position = to_local(player.global_position)
	los_raycast.force_raycast_update()
	
	return not los_raycast.is_colliding()

func lay_scent(tile_pos: Vector2i):
	scent_map[tile_pos] = FORCA_MAX_CHEIRO
	for x in range(-1, 2):
		for y in range(-1, 2):
			if x == 0 and y == 0: continue
			var neighbor_pos = tile_pos + Vector2i(x, y)
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
	
	for x in range(-1, 2):
		for y in range(-1, 2):
			if x == 0 and y == 0: continue
			var neighbor_tile = current_tile + Vector2i(x, y)
			if scent_map.has(neighbor_tile) and scent_map[neighbor_tile] > max_scent:
				max_scent = scent_map[neighbor_tile]
				best_scent_pos = tilemap.map_to_local(neighbor_tile)
	
	return (best_scent_pos - global_position).normalized()

func encontrar_rastro_mais_proximo() -> Vector2:
	if scent_map.is_empty():
		return global_position

	var rastro_mais_proximo = Vector2.ZERO
	var min_dist_sq = INF

	for tile_pos in scent_map.keys():
		var world_pos = tilemap.map_to_local(tile_pos)
		var dist_sq = global_position.distance_squared_to(world_pos)
		
		if dist_sq < min_dist_sq:
			min_dist_sq = dist_sq
			rastro_mais_proximo = world_pos
			
	return rastro_mais_proximo

# ================================================================
# --- LÓGICA DE MOVIMENTO E AÇÃO ---
# ================================================================
func _physics_process(delta: float) -> void:
	if Global.paused:
		return
	timer += delta
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		move_and_slide(); return

	if knockback:
		tempo_knockback += delta
		if tempo_knockback >= 0.4:
			knockback = false
		# CORREÇÃO: O sinal negativo foi removido daqui para o knockback funcionar corretamente.
		velocity = velocity.lerp(Vector2.ZERO, delta * 5.0)
		move_and_slide(); return

	var direcao_alvo = Vector2.ZERO

	match current_state:
		State.PERSEGUINDO:
			navigation_agent.target_position = player_last_known_position
			direcao_alvo = (navigation_agent.get_next_path_position() - global_position).normalized()
		
		State.PROCURANDO:
			var direcao_cheiro_local = get_best_scent_direction()
			
			if direcao_cheiro_local != Vector2.ZERO:
				direcao_alvo = direcao_cheiro_local
			else:
				var pos_rastro_global = encontrar_rastro_mais_proximo()
				
				if pos_rastro_global != global_position:
					navigation_agent.target_position = pos_rastro_global
					direcao_alvo = (navigation_agent.get_next_path_position() - global_position).normalized()
				else:
					direcao_alvo = Vector2.ZERO

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
	
	if current_state == State.PERSEGUINDO and (player.global_position - global_position).length() < 500:
		shoot()

# ================================================================
# --- Funções de Suporte ---
# ================================================================

func _get_context_steering_direction(direcao_alvo: Vector2) -> Vector2:
	var interest = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	var danger = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	
	for i in direcoes.size():
		var dot_product = direcoes[i].dot(direcao_alvo)
		interest[i] = max(0.0, dot_product)
		
		if dot_product > 0.9:
			interest[i] += BONUS_DIRECAO_GPS
	
	for i in raycasts.size():
		if raycasts[i].is_colliding():
			danger[i] = PERIGO_VALOR
			var vizinho_esquerda = (i - 1 + direcoes.size()) % direcoes.size()
			var vizinho_direita = (i + 1) % direcoes.size()
			danger[vizinho_esquerda] = max(danger[vizinho_esquerda], PERIGO_VALOR * 0.5)
			danger[vizinho_direita] = max(danger[vizinho_direita], PERIGO_VALOR * 0.5)

	var context_map = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	for i in direcoes.size():
		context_map[i] = interest[i] - danger[i]

	var melhor_direcao = Vector2.ZERO
	var max_valor = -INF
	for i in direcoes.size():
		if context_map[i] > max_valor:
			max_valor = context_map[i]
			melhor_direcao = direcoes[i]
	return melhor_direcao

func update_animation_and_flip():
	if velocity.length() > 10:
		sprite.play("Walking")
		if velocity.x > 0: sprite.flip_h = false
		elif velocity.x < 0: sprite.flip_h = true
	else:
		sprite.play("Idle")

func aplicar_knockback(direcao: Vector2):
	knockback = true
	tempo_knockback = 0.0
	velocity = direcao * forca_knockback

func _on_area_2d_body_entered(body: Node2D) -> void:
	if knockback:
		return
	if body.is_in_group("players"):
		var direcao = (global_position - body.global_position).normalized()
		aplicar_knockback(direcao)
	
	if knockback:
		return
		
	if body.is_in_group("players"):
		var direcao = (global_position - body.global_position).normalized()
		aplicar_knockback(direcao)

func shoot():
	if timer >= 1.2:
		var new_bullet = obj_tiro_azul.instantiate()
		var direction = (player.global_position - global_position).normalized()
		new_bullet.player = player
		new_bullet.global_position = global_position
		new_bullet.velocity = direction * velocidade * 1.5
		get_parent().add_child(new_bullet)
		timer = 0.0
