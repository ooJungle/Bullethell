extends CharacterBody2D

# --- Variáveis de Movimento e Combate ---
@export var speed: float = 300.0
@export var aceleracao: float = 1500.0
@export var atrito: float = 1200.0
@export var forca_salto_inimigo: float = 200.0

# --- Variáveis da Dilatação/Aceleração do Tempo ---
@export var raio_max_dilatacao: float = 500.0
@export var fator_tempo_maximo: float = 3.0
@export var raio_max_aceleracao: float = 500.0
@export var fator_tempo_minimo: float = 0.2

# --- Nós Filhos ---
@onready var sprite: AnimatedSprite2D = $sprite

# --- Variáveis Internas ---
var vida_maxima: int = 5
var vida: int = vida_maxima
var buraco_negro_proximo: Node2D = null
var buraco_minhoca_proximo: Node2D = null


func _ready() -> void:
	add_to_group("players")
	vida = vida_maxima


func take_damage(amount: int) -> void:
	vida -= amount
	print("Player tomou dano. Vida:", vida)
	if vida <= 0:
		die()


func die() -> void:
	print("morreu")


func _physics_process(delta: float) -> void:
	if Global.paused:
		return

	atualizar_fator_tempo()

	var forca_externa = calcular_forcas_externas()
	velocity += forca_externa * delta
	
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if input_direction != Vector2.ZERO:
		var target_velocity = input_direction * speed
		velocity = velocity.move_toward(target_velocity, aceleracao * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, atrito * delta)

	if input_direction.x > 0:
		sprite.flip_h = false
	elif input_direction.x < 0:
		sprite.flip_h = true

	if velocity.length() > 10.0:
		if sprite.animation != "Walking":
			sprite.play("Walking")
	else:
		if sprite.animation != "Idle":
			sprite.play("Idle")
	
	move_and_slide()
	handle_enemy_bounce()


func handle_enemy_bounce():
	if is_on_floor():
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			
			if collider and collider.is_in_group("enemies"):
				velocity.y = -forca_salto_inimigo
				break


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if not Global.paused:
			$".."/PauseMenu.start_pause()

# --- FUNÇÃO DE FÍSICA ATUALIZADA ---
func calcular_forcas_externas() -> Vector2:
	# --- NOVA VERIFICAÇÃO DE SOBREPOSIÇÃO ---
	var in_bn_field = false
	if is_instance_valid(buraco_negro_proximo) and global_position.distance_to(buraco_negro_proximo.global_position) < buraco_negro_proximo.raio_maximo:
		in_bn_field = true

	var in_wh_field = false
	if is_instance_valid(buraco_minhoca_proximo) and global_position.distance_to(buraco_minhoca_proximo.global_position) < buraco_minhoca_proximo.raio_maximo:
		in_wh_field = true

	# Se estiver em ambos os campos ao mesmo tempo, anula os efeitos
	if in_bn_field and in_wh_field:
		return Vector2.ZERO
	# --- FIM DA VERIFICAÇÃO ---

	var forca_total = Vector2.ZERO
	
	# Força de atração do Buraco Negro (apenas se não estiver sobreposto)
	if in_bn_field:
		var dist = global_position.distance_to(buraco_negro_proximo.global_position)
		if dist > 1.0:
			var direcao = (buraco_negro_proximo.global_position - global_position).normalized()
			var forca = (buraco_negro_proximo.forca_gravidade / max(sqrt(dist), 20))
			forca_total += direcao * forca
			
	# Força de repulsão do Buraco de Minhoca (apenas se não estiver sobreposto)
	if in_wh_field:
		var dist = global_position.distance_to(buraco_minhoca_proximo.global_position)
		if dist > 1.0:
			var direcao = (global_position - buraco_minhoca_proximo.global_position).normalized()
			var forca = (buraco_minhoca_proximo.forca_repulsao_campo / max(sqrt(dist), 20))
			forca_total += direcao * forca

	return forca_total


# --- Funções para a Dilatação e Aceleração do Tempo ---
func atualizar_fator_tempo():
	buraco_negro_proximo = encontrar_corpo_celeste_mais_proximo("buracos_negros")
	buraco_minhoca_proximo = encontrar_corpo_celeste_mais_proximo("buracos_minhoca")
	
	var efeito_buraco_negro = 1.0
	var efeito_buraco_minhoca = 1.0
	
	if is_instance_valid(buraco_negro_proximo):
		var dist = global_position.distance_to(buraco_negro_proximo.global_position)
		if dist < raio_max_dilatacao:
			efeito_buraco_negro = remap(dist, 0, raio_max_dilatacao, fator_tempo_maximo, 1.0)

	if is_instance_valid(buraco_minhoca_proximo):
		var dist = global_position.distance_to(buraco_minhoca_proximo.global_position)
		if dist < raio_max_aceleracao:
			efeito_buraco_minhoca = remap(dist, 0, raio_max_aceleracao, fator_tempo_minimo, 1.0)
	
	var fator_tempo_combinado = efeito_buraco_negro + efeito_buraco_minhoca - 1.0
	Global.fator_tempo = max(0.001, fator_tempo_combinado)


func encontrar_corpo_celeste_mais_proximo(grupo: String) -> Node2D:
	var nos_no_grupo = get_tree().get_nodes_in_group(grupo)
	var mais_proximo = null
	var min_dist = INF
	
	if nos_no_grupo.is_empty():
		return null

	for no in nos_no_grupo:
		var dist = global_position.distance_squared_to(no.global_position)
		if dist < min_dist:
			min_dist = dist
			mais_proximo = no
			
	return mais_proximo
