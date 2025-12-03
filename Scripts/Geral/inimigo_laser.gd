extends CharacterBody2D

# --- Variáveis de Movimento ---
@export var velocidade = 100.0

# --- Variáveis de Combate e Estados ---
@export var player: CharacterBody2D
@export_group("Timers do Ataque")
@export var duracaoMira: float = 2.0
@export var ducacaoLock: float = 0.5
@export var duracaoTiro: float = 1.0
@export var tiroCooldown: float = 5

# --- Variável de Tempo de Vida (FPS FIX) ---
@export var tempo_vida_maximo: float = 30.0 

# --- Nós Filhos ---
@onready var sprite: Sprite2D = $Inimigo
@onready var fire_point: Node2D = $FirePoint
@onready var linha: Line2D = $FirePoint/linha
@onready var linha_2: Line2D = $FirePoint/linha2
@onready var laserbeam: Sprite2D = $FirePoint/Laserbeam
@onready var ray_cast_2d: RayCast2D = $FirePoint/RayCast2D
@onready var collision_area: Area2D = $CollisionArea
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

# --- Máquina de Estados (FSM) ---
enum Estado { IDLE, MIRANDO, LOCKADO, ATIRANDO, COOLDOWN }
var estadoAtual = Estado.IDLE
var state_timer: float = 0.0
var locked_angle: float = 0.0
var alvo_atingido_neste_tiro: bool = false

# --- Variáveis de Knockback e Vida ---
var knockback = false
var tempo_knockback_atual = 0.0
var tempo_vida_atual: float = 0.0
@export var forca_knockback = 600.0

func _ready() -> void:
	add_to_group("inimigo")
	
	player = get_node_or_null("/root/Node2D/player")
	if not player:
		player = get_node_or_null("/root/fase_teste/player")
	
	mudar_para_estado(Estado.COOLDOWN)

func _physics_process(delta: float) -> void:
	if Global.paused or !visible:
		return
	
	# --- Lógica de Tempo de Vida ---
	tempo_vida_atual += delta * Global.fator_tempo
	if tempo_vida_atual >= tempo_vida_maximo:
		queue_free()
		return
		
	# --- Lógica de Knockback ---
	if knockback:
		tempo_knockback_atual += delta
		if tempo_knockback_atual >= 0.3:
			knockback = false
		velocity = velocity.lerp(Vector2.ZERO, delta * 5.0)
		move_and_slide()
		return

	# --- Rotação do Sprite ---
	if is_instance_valid(player):
		if estadoAtual in [Estado.IDLE, Estado.COOLDOWN, Estado.MIRANDO]:
			var direction_to_player = (player.global_position - global_position).normalized()
			sprite.rotation = direction_to_player.angle() + PI / 2

	# --- Movimentação Simplificada ---
	# O inimigo só se move se estiver em IDLE ou COOLDOWN e se o player existir
	if is_instance_valid(player) and estadoAtual in [Estado.IDLE, Estado.COOLDOWN]:
		# 1. Pega a direção: (Destino - Origem).normalized()
		var direcao = (player.global_position - global_position).normalized()
		
		# 2. Aplica a velocidade na direção
		velocity = direcao * velocidade * Global.fator_tempo
	else:
		# Se estiver atirando ou mirando, para suavemente
		velocity = velocity.lerp(Vector2.ZERO, delta * 5.0 * Global.fator_tempo)
	
	move_and_slide()

func _process(delta: float) -> void:
	if Global.paused or !visible:
		return
	
	match estadoAtual:
		Estado.IDLE:
			pass
		Estado.MIRANDO:
			modo_mira(delta)
		Estado.LOCKADO:
			modo_lockado(delta)
		Estado.ATIRANDO:
			modo_atirando(delta)
		Estado.COOLDOWN:
			modo_cooldown(delta)

func mudar_para_estado(novoEstado: Estado):
	estadoAtual = novoEstado
	linha.visible = false
	linha_2.visible = false
	laserbeam.visible = false
	
	match novoEstado:
		Estado.MIRANDO:
			state_timer = duracaoMira
			linha.visible = true
			linha_2.visible = true
			linha.default_color = Color("ffd900dc")
			linha_2.default_color = Color("ffd900dc")
		Estado.LOCKADO:
			state_timer = ducacaoLock
			linha.visible = true
			linha_2.visible = true
			linha.default_color = Color("ff7b00")
			linha_2.default_color = Color("ff7b00")
		Estado.ATIRANDO:
			state_timer = duracaoTiro
			laserbeam.visible = true
			alvo_atingido_neste_tiro = false
		Estado.COOLDOWN:
			state_timer = randf_range(3, tiroCooldown)
		Estado.IDLE:
			mudar_para_estado(Estado.COOLDOWN)
	
func modo_mira(delta: float):
	if is_instance_valid(player):
		var direcao_do_player = player.global_position - fire_point.global_position
		fire_point.rotation = direcao_do_player.angle()
	
	state_timer -= delta * Global.fator_tempo
	if state_timer <= 0:
		locked_angle = fire_point.rotation
		mudar_para_estado(Estado.LOCKADO)

func modo_lockado(delta: float):
	fire_point.rotation = locked_angle
	state_timer -= delta * Global.fator_tempo
	if state_timer <= 0:
		mudar_para_estado(Estado.ATIRANDO)
		audio_stream_player_2d.play()
func modo_atirando(delta: float):
	fire_point.rotation = locked_angle
	if not alvo_atingido_neste_tiro:
		ray_cast_2d.force_raycast_update()
		if ray_cast_2d.is_colliding():
			var collider = ray_cast_2d.get_collider()
			if collider == player:
				if "take_damage" in player: 
					player.take_damage(40)
				alvo_atingido_neste_tiro = true
	
	state_timer -= delta * Global.fator_tempo
	if state_timer <= 0:
		mudar_para_estado(Estado.COOLDOWN)

func modo_cooldown(delta: float):
	state_timer -= delta * Global.fator_tempo
	if state_timer <= 0:
		mudar_para_estado(Estado.MIRANDO)

func aplicar_knockback(direcao: Vector2):
	knockback = true
	tempo_knockback_atual = 0.0
	velocity = direcao * forca_knockback * 2
	if estadoAtual in [Estado.MIRANDO, Estado.LOCKADO, Estado.ATIRANDO]:
		mudar_para_estado(Estado.COOLDOWN)

func _on_collision_area_body_entered(body: Node2D) -> void:
	if knockback or body == self:
		return
	if body.is_in_group("player"):
		var direcao = (global_position - body.global_position).normalized()
		aplicar_knockback(direcao)
		if body.has_method("take_damage"):
			body.take_damage(5)

func take_damage(_amount: int) -> void:	
	queue_free()
