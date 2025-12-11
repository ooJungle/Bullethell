extends Node

# --- SINAIS ---
# Adição 1: O sinal que avisa que o dash ocorreu e passa o tempo de recarga
signal dash_realizado(tempo_cooldown)

# --- REFERÊNCIAS ---
@export var body: CharacterBody2D

# --- CONFIGURAÇÕES ---
@export_group("Status Base")
@export var speed: float = 300.0
@export var aceleracao: float = 1500.0
@export var atrito: float = 1200.0

@export_group("Dash")
@export var dash_speed: float = 1500.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 1.5

# --- VARIÁVEIS DE INTERFACE ---
var pode_se_mexer: bool = true
var last_move_direction: Vector2 = Vector2.DOWN # Valor padrão importante
var is_dashing: bool = false
var can_dash: bool = true

func _ready() -> void:
	if not body:
		body = get_parent()

func handle_movement(delta: float, forca_externa: Vector2) -> void:
	if not is_instance_valid(body): return

	# 1. Dash (Prioridade Máxima)
	if is_dashing:
		body.move_and_slide()
		return

	# 2. Bloqueio (Se Player mandou parar)
	if not pode_se_mexer:
		return

	# 3. Input Dash
	if Input.is_action_just_pressed("dash") and can_dash:
		start_dash()
		return

	# 4. Movimento Normal
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_direction.length() > 1.0: input_direction = input_direction.normalized()

	if input_direction != Vector2.ZERO:
		last_move_direction = input_direction.normalized() # Atualiza direção
		var target_velocity = input_direction * speed
		body.velocity = body.velocity.move_toward(target_velocity, aceleracao * delta)
	else:
		aplicar_friccao(delta)
	
	body.velocity += forca_externa * delta
	body.move_and_slide()

func aplicar_friccao(delta: float):
	body.velocity = body.velocity.move_toward(Vector2.ZERO, atrito * delta)

func start_dash():
	is_dashing = true
	can_dash = false
	
	# Adição 2: Dispara o aviso para quem estiver ouvindo (o Player)
	dash_realizado.emit(dash_cooldown)
	
	var dash_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dash_dir == Vector2.ZERO:
		dash_dir = last_move_direction
	
	body.velocity = dash_dir.normalized() * dash_speed
	body.modulate = Color(0.5, 1.5, 2.0, 0.7)

	await get_tree().create_timer(dash_duration).timeout
	
	is_dashing = false
	body.velocity = Vector2.ZERO
	body.modulate = Color.WHITE
	
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true
