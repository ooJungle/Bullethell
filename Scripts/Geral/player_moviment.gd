extends CharacterBody2D

@onready var player: CharacterBody2D = $"."
@onready var som_ataque: AudioStreamPlayer = $AudioStreamPlayer

# --- VARIÁVEIS DE JANELA (TRANSPARÊNCIA) ---
@onready var transparente: bool = true
@onready var ativo: bool = true

# --- COMBATE ---
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_colisao: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var sprite: AnimatedSprite2D = $sprite
@onready var dano_timer: Timer = $dano_timer
@onready var barra_carga: TextureProgressBar = $BarraCarga

const SWORD_BEAM_SCENE = preload("res://Cenas/Projeteis/sword_beam.tscn")

# --- GUIAS (SETA) ---
@onready var seta_pivo: Node2D = $SetaPivo
var alvo_seta: Vector2 = Vector2.ZERO
var offset_visual_seta: Vector2 = Vector2(0, -8)

# --- STATUS DO PLAYER (TOP-DOWN) ---
@export var speed: float = 300.0
@export var aceleracao: float = 1500.0
@export var atrito: float = 1200.0
@export var forca_salto_inimigo: float = 200.0
@export var raio_max_dilatacao: float = 500.0
@export var fator_tempo_maximo: float = 3.0
@export var raio_max_aceleracao: float = 500.0
@export var fator_tempo_minimo: float = 0.2
@export var dano_do_player: int = 10
@export var tempo_para_carregar: float = 1.5

# --- DASH TOP-DOWN ---
@export_group("Dash TopDown")
@export var dash_speed: float = 1500.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.6

# --- PLATAFORMA & DASH ESPECÍFICOS ---
@export_group("Plataforma e Dash")
@export var PLAT_SPEED: float = 250.0
@export var PLAT_JUMP_VELOCITY: float = -450.0
@export var PLAT_DASH_SPEED: float = 800.0
@export var ghost_node : PackedScene # Arraste a cena do fantasma aqui

# --- TIMERS E MARKERS ---
# Se não existirem na cena, crie nós Timer filhos do Player com esses nomes
@onready var ghost_timer: Timer = $GhostTimer 
@onready var dash_timer: Timer = $DashTimer
@onready var dash_cooldown_timer: Timer = $DashCooldown
@onready var ponto_do_rastro: Marker2D = $PontoDoRastro # Crie um Marker2D no pé do player

# --- VARIÁVEIS GERAIS ---
var is_dashing: bool = false
var can_dash: bool = true
var vida_maxima: int = 300
var vida: int = vida_maxima
var buraco_negro_proximo: Node2D = null
var buraco_minhoca_proximo: Node2D = null
var last_move_direction: Vector2 = Vector2.DOWN

var tem_arma: bool = true
var pode_atacar: bool = true
var atacando: bool = false
var arma_atual_dados: Dictionary

# VARIÁVEIS DE CARGA
var carga_atual: float = 0.0
var esta_carregando: bool = false

# VARIÁVEIS DE ANIMAÇÃO PLATAFORMA
var tempo_idle_plat: float = 0.0

# --- CONTROLE DE MOVIMENTO (Setter) ---
var pode_se_mexer: bool = true:
	set(valor):
		pode_se_mexer = valor
		if pode_se_mexer:
			resetar_combate()

func _ready() -> void:
	vida = vida_maxima
	Global.vida = vida
	hitbox_colisao.disabled = true
	
	if barra_carga:
		barra_carga.visible = false
		barra_carga.max_value = tempo_para_carregar
		barra_carga.value = 0
	
	if seta_pivo:
		seta_pivo.top_level = true 
		seta_pivo.visible = false
	
	if not sprite.animation_finished.is_connected(_on_sprite_animation_finished):
		sprite.animation_finished.connect(_on_sprite_animation_finished)
		
	# Conexão segura dos timers de Dash (Plataforma)
	if dash_timer and not dash_timer.timeout.is_connected(_on_dash_timer_timeout):
		dash_timer.timeout.connect(_on_dash_timer_timeout)
	if dash_cooldown_timer and not dash_cooldown_timer.timeout.is_connected(_on_dash_cooldown_timeout):
		dash_cooldown_timer.timeout.connect(_on_dash_cooldown_timeout)
	if ghost_timer and not ghost_timer.timeout.is_connected(_on_ghost_timer_timeout):
		ghost_timer.timeout.connect(_on_ghost_timer_timeout)

func _process(_delta: float) -> void:
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
		# Lógica de pause simples para parar animações
		if not Global.plataforma:
			if last_move_direction.y < 0: sprite.play("idle_costas")
			elif last_move_direction.y > 0: sprite.play("idle_frente")
			else: sprite.play("idle_lado")
		if barra_carga:
			barra_carga.visible = false
			esta_carregando = false 
			carga_atual = 0.0
		return

	# Se estiver dashando (Modo Plataforma trava movimento normal)
	if is_dashing and Global.plataforma:
		move_and_slide()
		return

	# Dash Top-Down (Modo Antigo)
	if not Global.plataforma and is_dashing:
		move_and_slide()
		return

	# Input de Dash Geral
	if Input.is_action_just_pressed("dash") and can_dash and pode_se_mexer:
		if Global.plataforma:
			start_platform_dash()
		else:
			iniciar_dash_topdown()

	# Bloqueio de Ataque
	if atacando and not sprite.animation in ["ataque_frente", "ataque_costas", "ataque_lado"]:
		atacando = false
		hitbox_colisao.disabled = true

	if atacando:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Ataque Carregado
	processar_ataque_carregado(delta)

	# --- LÓGICA PLATAFORMA ---
	if Global.plataforma:
		
		# 1. Gravidade
		if not is_on_floor():
			velocity += get_gravity() * delta

		# 2. Pulo Variável
		if Input.is_action_just_pressed("ui_accept") and is_on_floor() and pode_se_mexer:
			velocity.y = PLAT_JUMP_VELOCITY
		
		if Input.is_action_just_released("ui_accept") and velocity.y < 0:
			velocity.y *= 0.5 # Corte de pulo

		# 3. Movimento Horizontal
		var direction := Input.get_axis("move_left", "move_right")
		if direction and pode_se_mexer:
			velocity.x = direction * PLAT_SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, PLAT_SPEED)
		
		# 4. Virar Sprite
		if direction > 0:
			sprite.flip_h = true
		elif direction < 0:
			sprite.flip_h = false
			
		# 5. Sistema de Animações (Plataforma)
		atualizar_animacao_plataforma(direction)
	
	# --- LÓGICA TOP-DOWN ---
	else:
		atualizar_fator_tempo() # Mecânica de buracos negros
		
		var forca_externa = calcular_forcas_externas()
		velocity += forca_externa * delta
		
		if pode_se_mexer:
			var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
			if input_direction.length() > 1.0: input_direction = input_direction.normalized()
			
			if input_direction != Vector2.ZERO:
				var target_velocity = input_direction * speed
				velocity = velocity.move_toward(target_velocity, aceleracao * delta)
			else:
				velocity = velocity.move_toward(Vector2.ZERO, atrito * delta)
			
			if not atacando:
				atualizar_animacao_movimento_topdown(input_direction)
		else:
			velocity = Vector2.ZERO
			# Idle TopDown simples
			if last_move_direction.y < 0: sprite.play("idle_costas")
			elif last_move_direction.y > 0: sprite.play("idle_frente")
			else: sprite.play("idle_lado")
		
	move_and_slide()
	handle_enemy_bounce()
	global_position = global_position.round()

# --- ANIMAÇÕES (SEPARADAS POR MODO) ---

func atualizar_animacao_plataforma(direction: float):
	if is_on_floor():
		if direction == 0:
			tempo_idle_plat += get_process_delta_time()
			if tempo_idle_plat >= 2:
				if sprite.sprite_frames.has_animation("idle"): sprite.play("idle")
			else:
				if sprite.sprite_frames.has_animation("parado"): sprite.play("parado")
		else:
			tempo_idle_plat = 0
			if sprite.sprite_frames.has_animation("run"): sprite.play("run")
	else:
		# Animações de pulo
		if velocity.y < 0:
			if sprite.sprite_frames.has_animation("jump_up"): sprite.play("jump_up")
		elif velocity.y >= 0 and velocity.y < 250:
			if sprite.sprite_frames.has_animation("jump_middle"): sprite.play("jump_middle")
		else:
			if sprite.sprite_frames.has_animation("jump_down"): sprite.play("jump_down")

func atualizar_animacao_movimento_topdown(input_direction: Vector2):
	if velocity.length() > 10.0:
		if input_direction.y < 0:
			last_move_direction = Vector2.UP
			sprite.flip_h = false
			if sprite.animation != "andando_costas": sprite.play("andando_costas")
		elif input_direction.y > 0:
			last_move_direction = Vector2.DOWN
			sprite.flip_h = false
			if sprite.animation != "andando_frente": sprite.play("andando_frente")
		elif input_direction.x != 0:
			if sprite.animation != "andando_lado": sprite.play("andando_lado")
			if input_direction.x > 0:
				last_move_direction = Vector2.RIGHT
				sprite.flip_h = true
			elif input_direction.x < 0:
				last_move_direction = Vector2.LEFT
				sprite.flip_h = false
	else:
		if last_move_direction.y < 0:
			sprite.flip_h = true
			if sprite.animation != "idle_costas": sprite.play("idle_costas")
		elif last_move_direction.y > 0:
			sprite.flip_h = false
			if sprite.animation != "idle_frente": sprite.play("idle_frente")
		elif last_move_direction.x != 0:
			if sprite.animation != "idle_lado": sprite.play("idle_lado")
			if last_move_direction.x > 0: sprite.flip_h = false
			elif last_move_direction.x < 0: sprite.flip_h = true
		else:
			sprite.flip_h = true
			if sprite.animation != "idle_frente": sprite.play("idle_frente")

# --- SISTEMA DE DASH (Plataforma vs TopDown) ---

func start_platform_dash() -> void:
	# Ativa partículas se existirem
	if has_node("GPUParticles2D"):
		$GPUParticles2D.emitting = true
		
	is_dashing = true
	can_dash = false
	
	var dash_direction_x = Input.get_axis("move_left", "move_right")
	var dash_direction_y = 0.0
	
	if Input.is_action_pressed("move_up"):
		dash_direction_y = -1.0
	elif Input.is_action_pressed("move_down"):
		dash_direction_y = 1.0
		
	var dash_direction = Vector2(dash_direction_x, dash_direction_y).normalized()

	if dash_direction == Vector2.ZERO:
		var facing_direction = -1 if sprite.flip_h else 1
		dash_direction = Vector2(facing_direction, 0)
		
	velocity = dash_direction * PLAT_DASH_SPEED
	
	if dash_timer: dash_timer.start(0.2)
	if ghost_timer: ghost_timer.start(0.05)

func iniciar_dash_topdown():
	is_dashing = true
	can_dash = false
	sprite.modulate = Color(0.5, 1.5, 2.0, 0.7) 
	
	var dash_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dash_dir == Vector2.ZERO:
		dash_dir = last_move_direction
	velocity = dash_dir.normalized() * dash_speed
	
	await get_tree().create_timer(dash_duration).timeout
	
	is_dashing = false
	velocity = Vector2.ZERO
	sprite.modulate = Color.WHITE
	
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true

# --- FUNÇÕES DE TIMER DO DASH PLATAFORMA ---

func _on_dash_timer_timeout() -> void:
	if has_node("GPUParticles2D"):
		$GPUParticles2D.emitting = false
		
	is_dashing = false
	if Global.plataforma:
		velocity.x = move_toward(velocity.x, 0, PLAT_SPEED)
		velocity.y *= 0.5 
	else:
		velocity = Vector2.ZERO
		
	if dash_cooldown_timer: dash_cooldown_timer.start(0.5)
	if ghost_timer: ghost_timer.stop()

func _on_dash_cooldown_timeout() -> void:
	can_dash = true

func _on_ghost_timer_timeout() -> void:
	add_ghost()

func add_ghost():
	if not ghost_node:
		return
	var ghost = ghost_node.instantiate()
	get_tree().current_scene.add_child(ghost)
	if ponto_do_rastro:
		ghost.global_position = ponto_do_rastro.global_position
	else:
		ghost.global_position = global_position
		
	ghost.scale = self.scale
	ghost.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	ghost.flip_h = sprite.flip_h
	if ghost.has_method("fade_out"):
		ghost.fade_out()

# --- SISTEMA DE CARGA E ATAQUE ---

func processar_ataque_carregado(delta: float):
	if Input.is_action_pressed("attack") and pode_atacar and tem_arma and pode_se_mexer:
		esta_carregando = true
		if barra_carga:
			barra_carga.visible = true
		carga_atual += delta
		if carga_atual > tempo_para_carregar:
			carga_atual = tempo_para_carregar
			if barra_carga: barra_carga.modulate = Color(1, 0.2, 0.2)
		if barra_carga: barra_carga.value = carga_atual
	elif Input.is_action_just_released("attack"):
		if esta_carregando:
			if carga_atual >= tempo_para_carregar: iniciar_ataque(true) 
			else: iniciar_ataque(false)
		resetar_carga()
	elif not Input.is_action_pressed("attack") and esta_carregando:
		resetar_carga()

func resetar_carga():
	esta_carregando = false
	carga_atual = 0.0
	if barra_carga:
		barra_carga.value = 0.0
		barra_carga.visible = false
		barra_carga.modulate = Color.WHITE

func iniciar_ataque(com_projetil: bool):
	atacando = true
	pode_atacar = false
	hitbox_colisao.disabled = false
	posicionar_hitbox()
	if com_projetil: lancar_projetil()
	
	if last_move_direction.y < 0: sprite.play("ataque_costas")
	elif last_move_direction.y > 0: sprite.play("ataque_frente")
	elif last_move_direction.x != 0:
		sprite.play("ataque_lado")
		sprite.flip_h = (last_move_direction.x > 0)
	som_ataque.pitch_scale = randf_range(0.5, 2.0)
	som_ataque.play()
	verificar_dano_nos_inimigos()

func lancar_projetil():
	var beam = SWORD_BEAM_SCENE.instantiate()
	var offset = last_move_direction * 20.0 
	beam.global_position = global_position + offset + Vector2(0, -15)
	beam.direction = last_move_direction
	beam.rotation = last_move_direction.angle()
	get_tree().current_scene.add_child(beam)

func posicionar_hitbox():
	if last_move_direction.y < 0:
		hitbox.position = Vector2(11.5, -10); hitbox.rotation_degrees = -90
	elif last_move_direction.y > 0:
		hitbox.position = Vector2(-11.5, -5); hitbox.rotation_degrees = 90
	elif last_move_direction.x > 0:
		hitbox.position = Vector2(0, 0); hitbox.rotation_degrees = 0
	elif last_move_direction.x < 0:
		hitbox.position = Vector2(0, -23); hitbox.rotation_degrees = 180

func verificar_dano_nos_inimigos():
	await get_tree().physics_frame
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
		if last_move_direction.y < 0: sprite.play("idle_costas")
		elif last_move_direction.y > 0: sprite.play("idle_frente")
		else: sprite.play("idle_lado")

func resetar_combate():
	atacando = false
	pode_atacar = true
	hitbox_colisao.set_deferred("disabled", true) 
	resetar_carga()

# --- OUTROS (DANO, GUIA, FISICA EXTERNA) ---

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not Global.paused:
		get_node("%PauseMenu").start_pause()
			
func take_damage(amount: int) -> void:
	if not is_dashing:
		vida -= amount
		Global.vida = vida
		print("Player tomou dano. Vida:", vida)
		dano()
		if vida <= 0: die()

func die() -> void:
	print("morreu")
	get_tree().change_scene_to_file("res://Cenas/Menu/LostScene.tscn")

func dano():
	sprite.modulate = Color(1.0, 0.325, 0.349)
	dano_timer.start(0.3)

func _on_dano_timer_timeout() -> void:
	sprite.modulate = Color(1.0, 1.0, 1.0)

func ativar_seta_guia(posicao_do_portal: Vector2):
	alvo_seta = posicao_do_portal
	if seta_pivo: seta_pivo.visible = true; seta_pivo.z_index = 100

func desativar_seta_guia():
	if seta_pivo: seta_pivo.visible = false

func handle_enemy_bounce():
	if is_on_floor():
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			if collider and collider.is_in_group("inimigo"):
				velocity.y = -forca_salto_inimigo; break

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
