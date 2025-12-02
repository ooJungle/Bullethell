extends CharacterBody2D

@export_category("Atributos de Movimento")
@export var velocidade = 90.0
@export var forca_maxima_direcao = 180.0
@export var tempo_percepcao = 0.5
@export var distancia_de_parada = 15.0 # Impede que ele trema ao chegar no alvo

@export_category("Atributos de Combate")
@export var player: CharacterBody2D
@export var forca_knockback = 600.0
@export var velocidade_projetil = 130.0

const obj_tiro_roxo = preload("res://Cenas/Projeteis/tiro_polvo.tscn")
const obj_tiro_azul = preload("res://Cenas/Projeteis/tiro_polvo.tscn")
const obj_tiro_verde = preload("res://Cenas/Projeteis/tiro_polvo.tscn")

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var perception_timer: Timer = $PerceptionTimer

# Variáveis de Estado
var ataque_aleatorio = 0
var attack_cooldown = 0.0
var tempo_entre_tiros = 0.0
var limite_projeteis = 0
var rotacao_ataque = 200.0
var atirando = false
var direcao_ataque_fixa: Vector2 = Vector2.ZERO

var knockback = false
var tempo_knockback_atual = 0.0

func _ready() -> void:
	add_to_group("enemies")
	randomize()
	ataque_aleatorio = randi_range(0, 4)
	
	# Configurações para evitar travamentos na navegação
	navigation_agent.path_desired_distance = 20.0
	navigation_agent.target_desired_distance = 10.0
	
	perception_timer.one_shot = true
	perception_timer.wait_time = tempo_percepcao + randf_range(-0.3, 0.3)
	perception_timer.timeout.connect(on_perception_timer_timeout)
	perception_timer.start()
	
	# Busca segura pelo Player
	if not player:
		player = get_tree().get_first_node_in_group("player")
		if not player:
			player = get_node_or_null("/root/Node2D/player")
			if not player:
				player = get_node_or_null("/root/fase_teste/player")

func on_perception_timer_timeout() -> void:
	if Global.paused or !visible:
		perception_timer.start()
		return
	
	decidir_melhor_caminho()
	perception_timer.wait_time = tempo_percepcao + randf_range(-0.3, 0.3)
	perception_timer.start()

func _physics_process(delta: float) -> void:
	if Global.paused or !visible:
		return
	
	attack_cooldown += delta * Global.fator_tempo
	tempo_entre_tiros += delta * Global.fator_tempo
	
	# 1. Lógica de Knockback
	if knockback:
		tempo_knockback_atual += delta
		if tempo_knockback_atual >= 0.3:
			knockback = false
		velocity = velocity.lerp(Vector2.ZERO, delta * 5.0)
		move_and_slide()
		return

	if not is_instance_valid(player):
		velocity = velocity.lerp(Vector2.ZERO, delta * 3.0)
		move_and_slide()
		return

	# 2. Lógica de Movimento
	var direcao_alvo = Vector2.ZERO
	if not atirando:
		if not navigation_agent.is_navigation_finished():
			var proxima_posicao = navigation_agent.get_next_path_position()
			direcao_alvo = global_position.direction_to(proxima_posicao)
		
		# Se estiver muito perto, para de forçar movimento
		if global_position.distance_to(player.global_position) < distancia_de_parada:
			direcao_alvo = Vector2.ZERO

	if direcao_alvo.length() > 0:
		var velocidade_desejada = direcao_alvo * velocidade
		var forca_direcao = (velocidade_desejada - velocity).limit_length(forca_maxima_direcao)
		velocity += forca_direcao * delta * Global.fator_tempo
		velocity = velocity.limit_length(velocidade)
	else:
		velocity = velocity.lerp(Vector2.ZERO, delta * 3.0 * Global.fator_tempo)

	move_and_slide()
	
	# Verifica se pode atirar
	if (player.global_position - global_position).length() < 500:
		shoot()

func decidir_melhor_caminho() -> void:
	if not is_instance_valid(player) or atirando:
		return
	
	# Pequena otimização: se estiver muito perto, mira direto no player
	if global_position.distance_to(player.global_position) < 50:
		navigation_agent.target_position = player.global_position
		return

	var mapa_rid = navigation_agent.get_navigation_map()
	var pos_atual = global_position
	var pos_player = player.global_position

	# --- Lógica original mantida ---
	var caminho_direto = NavigationServer2D.map_get_path(mapa_rid, pos_atual, pos_player, true)
	var custo_caminho_direto = calcular_comprimento_do_caminho(caminho_direto)
	
	var custo_caminho_buraco = INF
	var buraco_negro_alvo = null
	
	var buraco_negro_proximo = encontrar_corpo_celeste_mais_proximo("buracos_negros")
	
	if is_instance_valid(buraco_negro_proximo) and is_instance_valid(buraco_negro_proximo.wormhole_exit):
		var pos_buraco_negro = buraco_negro_proximo.global_position
		var pos_saida_minhoca = buraco_negro_proximo.wormhole_exit.global_position
		
		var caminho_ate_buraco = NavigationServer2D.map_get_path(mapa_rid, pos_atual, pos_buraco_negro, true)
		var custo_ate_buraco = calcular_comprimento_do_caminho(caminho_ate_buraco)
		
		var caminho_da_saida = NavigationServer2D.map_get_path(mapa_rid, pos_saida_minhoca, pos_player, true)
		var custo_da_saida = calcular_comprimento_do_caminho(caminho_da_saida)
		
		custo_caminho_buraco = custo_ate_buraco + custo_da_saida
		buraco_negro_alvo = buraco_negro_proximo

	if custo_caminho_buraco < custo_caminho_direto:
		navigation_agent.target_position = buraco_negro_alvo.global_position
	else:
		navigation_agent.target_position = player.global_position

func calcular_comprimento_do_caminho(caminho: PackedVector2Array) -> float:
	var distancia = 0.0
	if caminho.size() < 2: return INF
	for i in range(caminho.size() - 1):
		distancia += caminho[i].distance_to(caminho[i+1])
	return distancia

func encontrar_corpo_celeste_mais_proximo(grupo: String) -> Node2D:
	var nos_no_grupo = get_tree().get_nodes_in_group(grupo)
	var mais_proximo = null
	var min_dist = INF
	for no in nos_no_grupo:
		var dist = global_position.distance_squared_to(no.global_position)
		if dist < min_dist:
			min_dist = dist
			mais_proximo = no
	return mais_proximo

# --- FUNÇÃO HELPER DE TIRO (AQUI ESTÁ A CORREÇÃO PRINCIPAL) ---
func spawn_bullet(scene: PackedScene, direction: Vector2, speed: float):
	var new_bullet = scene.instantiate()
	new_bullet.global_position = global_position
	new_bullet.velocity = direction * speed
	
	# 1. Adiciona à cena principal para não herdar movimento do pai
	get_tree().current_scene.add_child(new_bullet)
	
	# 2. SOLUÇÃO MÁGICA SEM LAYERS:
	# Diz para a física deste inimigo ignorar a física desta bala específica
	add_collision_exception_with(new_bullet)

func shoot():
	if ataque_aleatorio == 0:
		if not atirando:
			direcao_ataque_fixa = (player.global_position - global_position).normalized()
		if attack_cooldown >= 3:
			atirando = true
			if tempo_entre_tiros > 0.05: # Intervalo seguro
				rotacao_ataque += 0.1
				# Calcula direção rotacionada
				var dir_rotacionada = direcao_ataque_fixa.rotated(rotacao_ataque) 
				# Obs: No seu original você girava a velocidade. Aqui girei a direção. O efeito é o mesmo.
				
				spawn_bullet(obj_tiro_roxo, dir_rotacionada, velocidade_projetil)
				
				limite_projeteis += 1
				tempo_entre_tiros = 0.0
			if limite_projeteis > 30:
				reset_attack_state()

	elif ataque_aleatorio == 1:
		if attack_cooldown >= 3:
			for i in range(11):
				var direction = (player.global_position - global_position).normalized().rotated(deg_to_rad(360.0 / 11.0 * i))
				spawn_bullet(obj_tiro_roxo, direction, velocidade_projetil)
			reset_attack_state()

	elif ataque_aleatorio == 2:
		if attack_cooldown >= 3:
			var direction = (player.global_position - global_position).normalized()
			spawn_bullet(obj_tiro_roxo, direction, velocidade_projetil)
			reset_attack_state()

	elif ataque_aleatorio == 3:
		if attack_cooldown >= 3:
			var direction = (player.global_position - global_position).normalized()
			spawn_bullet(obj_tiro_azul, direction, velocidade_projetil)
			reset_attack_state()

	elif ataque_aleatorio == 4:
		if attack_cooldown >= 3:
			for i in range(4):
				var direction = (player.global_position - global_position).normalized()
				spawn_bullet(obj_tiro_verde, direction, velocidade_projetil)
			reset_attack_state()

func reset_attack_state():
	attack_cooldown = 0.0
	limite_projeteis = 0
	rotacao_ataque = 200.0
	atirando = false
	ataque_aleatorio = randi_range(0, 4)

func aplicar_knockback(direcao: Vector2):
	knockback = true
	tempo_knockback_atual = 0.0
	velocity = direcao * forca_knockback * 0.6 # Reduzi um pouco para controlar melhor

func _on_collision_area_body_entered(body: Node2D) -> void:
	if knockback or body == self:
		return
	
	# Se colidir com player, aplica knockback e dano
	if body.is_in_group("player"):
		var direcao = (global_position - body.global_position).normalized()
		aplicar_knockback(direcao)
		if body.has_method("take_damage"):
			body.take_damage(5)

func take_damage(_amount: int) -> void:	
	queue_free()
