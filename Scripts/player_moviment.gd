extends CharacterBody2D

@onready var player: CharacterBody2D = $"."

# --- VARIÁVEIS DE JANELA (TRANSPARÊNCIA) ---
@onready var transparente: bool = true
@onready var ativo: bool = true

# --- COMBATE ---
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_colisao: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var sprite: AnimatedSprite2D = $sprite
@onready var dano_timer: Timer = $dano_timer

# --- GUIAS (SETA) ---
@onready var seta_pivo: Node2D = $SetaPivo
var alvo_seta: Vector2 = Vector2.ZERO
# Ajuste este valor para subir ou descer o centro da rotação da seta
var offset_visual_seta: Vector2 = Vector2(0, -8)

# --- STATUS DO PLAYER ---
@export var speed: float = 300.0
@export var aceleracao: float = 1500.0
@export var atrito: float = 1200.0
@export var forca_salto_inimigo: float = 200.0
@export var raio_max_dilatacao: float = 500.0
@export var fator_tempo_maximo: float = 3.0
@export var raio_max_aceleracao: float = 500.0
@export var fator_tempo_minimo: float = 0.2
@export var dano_do_player: int = 10

var vida_maxima: int = 300
var vida: int = vida_maxima
var buraco_negro_proximo: Node2D = null
var buraco_minhoca_proximo: Node2D = null
var JUMP_VELOCITY = -450
var SPEED = 250
var last_move_direction: Vector2 = Vector2.DOWN

var tem_arma: bool = true
var pode_atacar: bool = true
var atacando: bool = false
var arma_atual_dados: Dictionary

func _ready() -> void:
	vida = vida_maxima
	Global.vida = vida
	hitbox_colisao.disabled = true
	
	# --- CORREÇÃO DA ÓRBITA DA SETA ---
	if seta_pivo:
		seta_pivo.top_level = true # Desacopla do corpo
		seta_pivo.visible = false
	
	if not sprite.animation_finished.is_connected(_on_sprite_animation_finished):
		sprite.animation_finished.connect(_on_sprite_animation_finished)

func _process(delta: float) -> void:
	# --- LÓGICA DE TRANSPARÊNCIA DA JANELA (INICIALIZAÇÃO) ---
	if transparente:
		get_tree().get_root().set_transparent_background(true)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true, 0)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true, 0)
		ativo = false
		transparente = false

	if seta_pivo and seta_pivo.visible:
		seta_pivo.global_position = global_position + offset_visual_seta
		seta_pivo.look_at(alvo_seta)

func _physics_process(delta: float) -> void:
	if Global.paused:
		if last_move_direction.y < 0:
			sprite.play("idle_costas")
		elif last_move_direction.y > 0:
			sprite.play("idle_frente")
		else:
			sprite.play("idle_lado")
		return
	
	# Segurança contra travamento
	if atacando and not sprite.animation in ["ataque_frente", "ataque_costas", "ataque_lado"]:
		atacando = false
		hitbox_colisao.disabled = true

	if atacando:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Input de Ataque (Input Map: "attack")
	if Input.is_action_just_pressed("attack") and pode_atacar and tem_arma:
		iniciar_ataque()

	# Lógica de Plataforma
	if Global.plataforma:
		if not is_on_floor():
			velocity += get_gravity() * delta
		var direction := Input.get_axis("move_left", "move_right")
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
		
		if direction > 0:
			sprite.flip_h = false
		elif direction < 0:
			sprite.flip_h = true
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY
		
		if Input.is_action_just_released("ui_accept") and velocity.y < 0:
			velocity.y *= 0.5
	
	# Lógica Top-Down
	else:
		atualizar_fator_tempo()

		var forca_externa = calcular_forcas_externas()
		velocity += forca_externa * delta
		
		var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")

		if input_direction.length() > 1.0:
			input_direction = input_direction.normalized()
		
		if input_direction != Vector2.ZERO:
			var target_velocity = input_direction * speed
			velocity = velocity.move_toward(target_velocity, aceleracao * delta)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, atrito * delta)
		
		if velocity.length() < 0.1:
			velocity = Vector2.ZERO
			
		if not atacando:
			atualizar_animacao_movimento(input_direction)
		
	move_and_slide()
	handle_enemy_bounce()

	# Arredonda a posição para evitar subpixels
	global_position = global_position.round()
	
# --- SISTEMA DE ATAQUE ---
func iniciar_ataque():
	atacando = true
	pode_atacar = false
	hitbox_colisao.disabled = false
	
	posicionar_hitbox()
	
	if last_move_direction.y < 0: # Costas
		sprite.play("ataque_costas")
	elif last_move_direction.y > 0: # Frente
		sprite.play("ataque_frente")
	elif last_move_direction.x != 0: # Lado
		sprite.play("ataque_lado")
		sprite.flip_h = (last_move_direction.x < 0)

	verificar_dano_nos_inimigos()

func posicionar_hitbox():
	if last_move_direction.y < 0: # Cima
		hitbox.position = Vector2(11.5, -10)
		hitbox.rotation_degrees = -90
	elif last_move_direction.y > 0: # Baixo
		hitbox.position = Vector2(-11.5, -5)
		hitbox.rotation_degrees = 90
	elif last_move_direction.x > 0: # Direita
		hitbox.position = Vector2(0, 0)
		hitbox.rotation_degrees = 0
	elif last_move_direction.x < 0: # Esquerda
		hitbox.position = Vector2(0, -23)
		hitbox.rotation_degrees = 180

func verificar_dano_nos_inimigos():
	await get_tree().physics_frame
	
	var corpos = hitbox.get_overlapping_bodies()
	
	for corpo in corpos:
		if (corpo.is_in_group("inimigo") or corpo.is_in_group("cristais") or corpo.is_in_group("boss")) and corpo.has_method("take_damage"):
			corpo.take_damage(dano_do_player)
			
			if corpo.is_in_group("inimigo") and "velocity" in corpo:
				var direcao_empurrao = (corpo.global_position - global_position).normalized()
				corpo.velocity += direcao_empurrao * 300

func _on_sprite_animation_finished():
	if sprite.animation in ["ataque_frente", "ataque_costas", "ataque_lado"]:
		atacando = false
		pode_atacar = true
		hitbox_colisao.disabled = true
		
		if last_move_direction.y < 0:
			sprite.play("idle_costas")
		elif last_move_direction.y > 0:
			sprite.play("idle_frente")
		else:
			sprite.play("idle_lado")

# --- SISTEMA DE GUIA (SETA) ---

func ativar_seta_guia(posicao_do_portal: Vector2):
	alvo_seta = posicao_do_portal
	if seta_pivo:
		seta_pivo.visible = true
		seta_pivo.z_index = 100

func desativar_seta_guia():
	if seta_pivo:
		seta_pivo.visible = false

# --- ANIMAÇÕES DE MOVIMENTO ---

func atualizar_animacao_movimento(input_direction: Vector2):
	if velocity.length() > 10.0:
		if input_direction.y < 0:
			last_move_direction = Vector2.UP
			sprite.flip_h = false
			if sprite.animation != "andando_costas":
				sprite.play("andando_costas")
		elif input_direction.y > 0:
			last_move_direction = Vector2.DOWN
			sprite.flip_h = false
			if sprite.animation != "andando_frente":
				sprite.play("andando_frente")
		elif input_direction.x != 0:
			if sprite.animation != "andando_lado":
				sprite.play("andando_lado")
			if input_direction.x > 0:
				last_move_direction = Vector2.RIGHT
				sprite.flip_h = false
			elif input_direction.x < 0:
				last_move_direction = Vector2.LEFT
				sprite.flip_h = true
	else:
		if last_move_direction.y < 0:
			sprite.flip_h = false
			if sprite.animation != "idle_costas":
				sprite.play("idle_costas")
		elif last_move_direction.y > 0:
			sprite.flip_h = false
			if sprite.animation != "idle_frente":
				sprite.play("idle_frente")
		elif last_move_direction.x != 0:
			if sprite.animation != "idle_lado":
				sprite.play("idle_lado")
			if last_move_direction.x > 0:
				sprite.flip_h = false
			elif last_move_direction.x < 0:
				sprite.flip_h = true
		else:
			sprite.flip_h = false
			if sprite.animation != "idle_frente":
				sprite.play("idle_frente")

# --- OUTROS SISTEMAS ---

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if not Global.paused:
			get_node("%PauseMenu").start_pause()
			
func take_damage(amount: int) -> void:
	vida -= amount
	Global.vida = vida
	print("Player tomou dano. Vida:", vida)
	
	dano()
	if vida <= 0:
		die()

func die() -> void:
	print("morreu")
	get_tree().change_scene_to_file("res://Cenas/Menu/LostScene.tscn")

func dano():
	sprite.modulate = Color(1.0, 0.325, 0.349)
	dano_timer.start(0.3)

func handle_enemy_bounce():
	if is_on_floor():
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			if collider and collider.is_in_group("inimigo"):
				velocity.y = -forca_salto_inimigo
				break
			
func calcular_forcas_externas() -> Vector2:
	var in_bn_field = false
	if is_instance_valid(buraco_negro_proximo) and global_position.distance_to(buraco_negro_proximo.global_position) < buraco_negro_proximo.raio_maximo:
		in_bn_field = true

	var in_wh_field = false
	if is_instance_valid(buraco_minhoca_proximo) and global_position.distance_to(buraco_minhoca_proximo.global_position) < buraco_minhoca_proximo.raio_maximo:
		in_wh_field = true

	if in_bn_field and in_wh_field:
		return Vector2.ZERO

	var forca_total = Vector2.ZERO
	
	if in_bn_field:
		var dist = global_position.distance_to(buraco_negro_proximo.global_position)
		if dist > 1.0:
			var direcao = (buraco_negro_proximo.global_position - global_position).normalized()
			var forca = (buraco_negro_proximo.forca_gravidade / max(sqrt(dist), 20))
			forca_total += direcao * forca
			
	if in_wh_field:
		var dist = global_position.distance_to(buraco_minhoca_proximo.global_position)
		if dist > 1.0:
			var direcao = (global_position - buraco_minhoca_proximo.global_position).normalized()
			var forca = (buraco_minhoca_proximo.forca_repulsao_campo / max(sqrt(dist), 20))
			forca_total += direcao * forca

	return forca_total

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
	
	if nos_no_grupo.is_empty(): return null

	for no in nos_no_grupo:
		var dist = global_position.distance_squared_to(no.global_position)
		if dist < min_dist:
			min_dist = dist
			mais_proximo = no
			
	return mais_proximo

func _on_dano_timer_timeout() -> void:
	sprite.modulate = Color(1.0, 1.0, 1.0)
