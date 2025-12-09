extends Node

# --- REFERÊNCIAS EXTERNAS ---
@export var body: CharacterBody2D
@export var jogador_vivo: AnimatedSprite2D
@export var ponto_do_rastro: Marker2D
@export var ghost_node : PackedScene

# --- NÓS FILHOS ---
@onready var ghost_timer: Timer = $GhostTimer
@onready var dash_timer: Timer = $DashTimer
@onready var dash_cooldown: Timer = $DashCooldown
@onready var particles: GPUParticles2D = $GPUParticles2D
@onready var dash_som: AudioStreamPlayer2D = $dash

# --- CONFIGURAÇÕES ---
const SPEED = 250.0
const JUMP_VELOCITY = -450.0
const DASH_SPEED = 800.0

# --- ESTADO ---
var can_dash = true
var is_dashing = false
var tempo = 0

# --- INTERFACE ---
var pode_se_mexer: bool = true
var last_move_direction: Vector2 = Vector2.RIGHT 

func _ready() -> void:
	if not body:
		body = get_parent()
	
	# --- CONFIGURAÇÃO DE SEGURANÇA DOS TIMERS ---
	if dash_timer:
		dash_timer.one_shot = true
		dash_timer.wait_time = 0.2
		if not dash_timer.timeout.is_connected(_on_dash_timer_timeout):
			dash_timer.timeout.connect(_on_dash_timer_timeout)
			
	if dash_cooldown:
		dash_cooldown.one_shot = true
		dash_cooldown.wait_time = 0.5
		if not dash_cooldown.timeout.is_connected(_on_dash_cooldown_timeout):
			dash_cooldown.timeout.connect(_on_dash_cooldown_timeout)
			
	if ghost_timer:
		ghost_timer.wait_time = 0.05
		if not ghost_timer.timeout.is_connected(_on_ghost_timer_timeout):
			ghost_timer.timeout.connect(_on_ghost_timer_timeout)

func handle_movement(delta: float) -> void:
	if not is_instance_valid(body): return

	# 1. Dash
	if is_dashing:
		body.move_and_slide()
		return 
	
	# 2. Gravidade
	if not body.is_on_floor():
		body.velocity += body.get_gravity() * delta

	# 3. Bloqueio (Ataque)
	if not pode_se_mexer:
		body.velocity.x = move_toward(body.velocity.x, 0, SPEED)
		processar_animacoes(0)
		body.move_and_slide()
		return

	# 4. Pulo
	if Input.is_action_just_pressed("ui_accept") and body.is_on_floor():
		body.velocity.y = JUMP_VELOCITY
	
	if Input.is_action_just_released("ui_accept") and body.velocity.y < 0:
		body.velocity.y *= 0.5

	# 5. Dash Input
	if Input.is_action_just_pressed("dash") and can_dash:
		start_dash()
	else:
		# 6. Movimento Horizontal
		var direction = Input.get_axis("move_left", "move_right")
		if direction:
			body.velocity.x = direction * SPEED
			last_move_direction = Vector2(direction, 0)
			
			# --- CORREÇÃO DO FLIP ---
			if direction > 0:
				jogador_vivo.flip_h = false # Direita (Normal)
			elif direction < 0:
				jogador_vivo.flip_h = true  # Esquerda (Invertido)
		else:
			body.velocity.x = move_toward(body.velocity.x, 0, SPEED)
		
		processar_animacoes(delta, direction)
			
	body.move_and_slide()

func processar_animacoes(delta: float, direction: float = 0.0):
	if not pode_se_mexer: return

	if body.is_on_floor():
		if abs(body.velocity.x) < 10:
			tempo += delta
			if tempo >= 2:
				tocar_anim("idle")
			else:
				tocar_anim("parado")
		else:
			tempo = 0
			# --- CORREÇÃO DO NOME DA ANIMAÇÃO ---
			tocar_anim("andando_lado") 
	else:
		if body.velocity.y < 0:
			tocar_anim("jump_up")
		elif body.velocity.y >= 0 and body.velocity.y < 250:
			tocar_anim("jump_middle")
		else:
			tocar_anim("jump_down")

func tocar_anim(nome: String):
	if jogador_vivo and jogador_vivo.sprite_frames.has_animation(nome):
		if jogador_vivo.animation != nome:
			jogador_vivo.play(nome)

func start_dash() -> void:
	print("Dash Iniciado!") 
	if dash_som: dash_som.play()
	if particles: particles.emitting = true
	
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
		var facing_direction = -1 if jogador_vivo.flip_h else 1
		dash_direction = Vector2(facing_direction, 0)
		
	body.velocity = dash_direction * DASH_SPEED
	
	dash_timer.start()
	ghost_timer.start()

func _on_dash_timer_timeout() -> void:
	print("Dash Acabou. Iniciando Cooldown...") 
	if particles: particles.emitting = false
	is_dashing = false
	body.velocity = Vector2.ZERO
	
	ghost_timer.stop()
	dash_cooldown.start() 

func _on_dash_cooldown_timeout() -> void:
	print("Dash Pronto!") 
	can_dash = true
	
func add_ghost():
	if not ghost_node: return
	var ghost = ghost_node.instantiate()
	get_tree().current_scene.add_child(ghost)
	
	if ponto_do_rastro:
		ghost.global_position = ponto_do_rastro.global_position
	else:
		ghost.global_position = body.global_position
		
	ghost.scale = body.scale * 1.5
	ghost.texture = jogador_vivo.sprite_frames.get_frame_texture(jogador_vivo.animation, jogador_vivo.frame)
	ghost.flip_h = jogador_vivo.flip_h
	
	if ghost.has_method("fade_out"):
		ghost.fade_out()

func _on_ghost_timer_timeout() -> void:
	add_ghost()
