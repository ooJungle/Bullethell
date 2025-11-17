extends CharacterBody2D

# --- Variáveis de Movimento e Combate ---
@export var velocidade = 100.0 # Representa a velocidade MÁXIMA BASE
@export var player: CharacterBody2D
@export var forca_maxima_direcao = 200.0 # Quão rápido o inimigo pode virar.
@export var forca_knockback = 450.0

# --- Nós Filhos ---
@onready var sprite: AnimatedSprite2D = $sprite
@onready var navigation_agent := $NavigationAgent2D as NavigationAgent2D
@onready var area_deteccao: Area2D = $Area2D
@onready var perception_timer: Timer = $PerceptionTimer

# --- Disparos ---
const obj_tiro_azul = preload("res://Cenas/Projeteis/projetil_espiral.tscn")
var timer = 0.0

# --- Knockback ---
var knockback = false
var tempo_knockback = 0.0


func _ready() -> void:
	add_to_group("enemies")
	perception_timer.timeout.connect(makepath)
	
	player = get_node_or_null("/root/Node2D/player")
	if not player:
		player = get_node_or_null("/root/fase_teste/player")
	makepath()


# ================================================================
# --- LÓGICA DE MOVIMENTO E AÇÃO ---
# ================================================================

func _physics_process(delta: float) -> void:
	if Global.paused or !visible:
		return
	timer += delta  * Global.fator_tempo
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		move_and_slide(); return

	if knockback:
		tempo_knockback += delta
		if tempo_knockback >= 0.4:
			knockback = false
		velocity = velocity.lerp(Vector2.ZERO, delta * 5.0 * Global.fator_tempo)
		move_and_slide(); return

	var direcao_alvo = Vector2.ZERO
	if not navigation_agent.is_navigation_finished():
		direcao_alvo = global_position.direction_to(navigation_agent.get_next_path_position())

	if direcao_alvo.length() > 0:
		var velocidade_desejada = direcao_alvo * velocidade * Global.fator_tempo
		var forca_direcao = velocidade_desejada - velocity
		forca_direcao = forca_direcao.limit_length(forca_maxima_direcao)
		velocity += forca_direcao * delta * Global.fator_tempo
		velocity = velocity.limit_length(velocidade * Global.fator_tempo)
	else:
		velocity = velocity.lerp(Vector2.ZERO, delta * 3.0 * Global.fator_tempo)

	move_and_slide()
	
	update_animation_and_flip()
	
	if is_instance_valid(player) and (player.global_position - global_position).length() < 500:
		shoot()


# --- FUNÇÃO DE PLANEAMENTO DE ROTA ESTRATÉGICA (ATUALIZADA) ---
func makepath() -> void:
	if not is_instance_valid(player):
		return

	var mapa_rid = navigation_agent.get_navigation_map()
	var pos_atual = global_position
	var pos_player = player.global_position

	# --- ROTA A: Custo do caminho direto ---
	var caminho_direto = NavigationServer2D.map_get_path(mapa_rid, pos_atual, pos_player, true)
	var custo_caminho_direto = calcular_comprimento_do_caminho(caminho_direto)
	
	# --- ROTA B: Custo do caminho pelo Buraco Negro ---
	var custo_caminho_buraco = INF # Começa como infinito
	var buraco_negro_alvo = null
	
	# Encontra o buraco negro mais próximo (poderia ser otimizado para verificar todos)
	var buraco_negro_proximo = encontrar_corpo_celeste_mais_proximo("buracos_negros")
	
	if is_instance_valid(buraco_negro_proximo) and is_instance_valid(buraco_negro_proximo.wormhole_exit):
		var pos_buraco_negro = buraco_negro_proximo.global_position
		var pos_saida_minhoca = buraco_negro_proximo.wormhole_exit.global_position
		
		# Custo para ir do inimigo até o buraco negro
		var caminho_ate_buraco = NavigationServer2D.map_get_path(mapa_rid, pos_atual, pos_buraco_negro, true)
		var custo_ate_buraco = calcular_comprimento_do_caminho(caminho_ate_buraco)
		
		# Custo para ir da saída do buraco de minhoca até o jogador
		var caminho_da_saida = NavigationServer2D.map_get_path(mapa_rid, pos_saida_minhoca, pos_player, true)
		var custo_da_saida = calcular_comprimento_do_caminho(caminho_da_saida)
		
		# O custo total é a soma das duas partes
		custo_caminho_buraco = custo_ate_buraco + custo_da_saida
		buraco_negro_alvo = buraco_negro_proximo

	# --- A DECISÃO ---
	if custo_caminho_buraco < custo_caminho_direto:
		# Se o caminho pelo buraco é mais curto, o alvo é o buraco negro
		navigation_agent.target_position = buraco_negro_alvo.global_position
	else:
		# Caso contrário, o alvo é o jogador
		navigation_agent.target_position = player.global_position


# ================================================================
# --- Funções de Suporte ---
# ================================================================

func calcular_comprimento_do_caminho(caminho: PackedVector2Array) -> float:
	var distancia = 0.0
	if caminho.size() < 2:
		return INF # Retorna infinito se o caminho for inválido
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
	if body == self: return
	if knockback: return
	if body.is_in_group("player"):
		var direcao = (global_position - body.global_position).normalized()
		aplicar_knockback(direcao)
		body.take_damage(5)

func shoot():
	if timer >= 4:
		var new_bullet = obj_tiro_azul.instantiate()
		var direction = (player.global_position - global_position).normalized()
		new_bullet.global_position = global_position
		new_bullet.velocity = direction * velocidade * 1.5
		get_parent().add_child(new_bullet)
		timer = 0.0
