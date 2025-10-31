extends CharacterBody2D

# --- Variáveis de Movimento e Percepção ---
@export var velocidade = 150.0 # Velocidade máxima de movimento.
@export var forca_maxima_direcao = 200.0 # Quão rápido o inimigo pode mudar de direção (aceleração/steering).
@export var tempo_percepcao = 0.5 # A cada quantos segundos o inimigo recalcula o caminho.

# --- Variáveis de Combate ---
@export var player: CharacterBody2D
@export var forca_knockback = 600.0 # Força do empurrão ao receber knockback.
const obj_tiro_azul = preload("res://Cenas/Projeteis/tiro_azul.tscn")

# --- Nós Filhos (Adicione-os na cena do inimigo!) ---
@onready var sprite: AnimatedSprite2D = $sprite
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var perception_timer: Timer = $PerceptionTimer
@onready var collision_area: Area2D = $CollisionArea

# --- Variáveis de Estado Interno ---
var shoot_timer = 0.0
var knockback = false
var tempo_knockback_atual = 0.0


func _ready() -> void:
	player = get_node_or_null("/root/Node2D/player")

	add_to_group("enemies")
	# O nome da função conectada foi mudado para a nova função estratégica
	perception_timer.wait_time = tempo_percepcao
	perception_timer.timeout.connect(decidir_melhor_caminho)

	# Calcula o caminho inicial.
	decidir_melhor_caminho()


func _physics_process(delta: float) -> void:
	if Global.paused:
		return
	
	shoot_timer += delta * Global.fator_tempo
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# --- LÓGICA DE KNOCKBACK ---
	if knockback:
		tempo_knockback_atual += delta
		if tempo_knockback_atual >= 0.3:
			knockback = false
		
		velocity = velocity.lerp(Vector2.ZERO, delta * 5.0)
		move_and_slide()
		return

	# --- LÓGICA DE MOVIMENTO COM PATHFINDING ---
	var direcao_alvo = Vector2.ZERO
	if not navigation_agent.is_navigation_finished():
		direcao_alvo = global_position.direction_to(navigation_agent.get_next_path_position())

	if direcao_alvo.length() > 0:
		var velocidade_desejada = direcao_alvo * velocidade
		var forca_direcao = velocidade_desejada - velocity
		forca_direcao = forca_direcao.limit_length(forca_maxima_direcao)
		
		velocity += forca_direcao * delta * Global.fator_tempo
		velocity = velocity.limit_length(velocidade)
	else:
		velocity = velocity.lerp(Vector2.ZERO, delta * 3.0 * Global.fator_tempo)

	move_and_slide()
	
	update_animation_and_flip()
	
	if (player.global_position - global_position).length() < 500:
		shoot()


# ================================================================
# --- NOVA LÓGICA DE PLANEAMENTO DE ROTA ESTRATÉGICO ---
# (Substitui a função 'recalcular_caminho' anterior)
# ================================================================

func decidir_melhor_caminho() -> void:
	if not is_instance_valid(player):
		return

	var mapa_rid = navigation_agent.get_navigation_map()
	var pos_atual = global_position
	var pos_player = player.global_position

	# --- ROTA A: Custo do caminho direto ---
	var caminho_direto = NavigationServer2D.map_get_path(mapa_rid, pos_atual, pos_player, true)
	var custo_caminho_direto = calcular_comprimento_do_caminho(caminho_direto)
	
	# --- ROTA B: Custo do caminho pelo Buraco Negro ---
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

	# --- A DECISÃO ---
	if custo_caminho_buraco < custo_caminho_direto:
		navigation_agent.target_position = buraco_negro_alvo.global_position
	else:
		navigation_agent.target_position = player.global_position

# --- FUNÇÕES DE SUPORTE PARA A NOVA LÓGICA ---

func calcular_comprimento_do_caminho(caminho: PackedVector2Array) -> float:
	var distancia = 0.0
	if caminho.size() < 2:
		return INF
	for i in range(caminho.size() - 1):
		distancia += caminho[i].distance_to(caminho[i+1])
	return distancia


func encontrar_corpo_celeste_mais_proximo(grupo: String) -> Node2D:
	var nos_no_grupo = get_tree().get_nodes_in_group(grupo)
	var mais_proximo = null
	var min_dist = INF
	if nos_no_grupo.is_empty(): return null
	for no in nos_no_grupo:
		var dist = global_position.distance_squared_to(no.global_position)
		if dist < min_dist:
			min_dist = dist
			mais_proximo = no
	return mais_proximo

# --- OUTRAS FUNÇÕES (INALTERADAS) ---

func shoot():
	if shoot_timer >= 1.2:
		var new_bullet = obj_tiro_azul.instantiate()
		var direction = (player.global_position - global_position).normalized()
		
		new_bullet.position = global_position
		get_parent().add_child(new_bullet)
		shoot_timer = 0.0

func update_animation_and_flip():
	if velocity.length() > 10:
		sprite.play("Walking")
		if velocity.x > 0: sprite.flip_h = false
		elif velocity.x < 0: sprite.flip_h = true
	else:
		sprite.play("Idle")

func aplicar_knockback(direcao: Vector2):
	knockback = true
	tempo_knockback_atual = 0.0
	velocity = direcao * forca_knockback

func _on_collision_area_body_entered(body: Node2D) -> void:
	if knockback or body == self:
		return
	
	if body.is_in_group("player"):
		var direcao = (global_position - body.global_position).normalized()
		aplicar_knockback(direcao)
		body.take_damage(5)
