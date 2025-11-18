extends CharacterBody2D

# --- Variáveis de Movimento e Percepção ---
@export var velocidade = 90.0
@export var forca_maxima_direcao = 180.0
@export var tempo_percepcao = 0.5

# --- Variáveis de Combate ---
@export var player: CharacterBody2D
@export var forca_knockback = 600.0
@export var velocidade_projetil = 130.0
const obj_tiro_roxo = preload("res://Cenas/Projeteis/tiro_central.tscn")

# --- Nós Filhos ---
@onready var sprite: AnimatedSprite2D = $sprite
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var perception_timer: Timer = $PerceptionTimer
@onready var collision_area: Area2D = $CollisionArea

# --- Variáveis de Estado ---
var attack_cooldown = 0.0
var knockback = false
var tempo_knockback_atual = 0.0


func _ready() -> void:
	add_to_group("enemies")
	
	sprite.rotation_degrees = 90 

	perception_timer.wait_time = tempo_percepcao
	perception_timer.timeout.connect(recalcular_caminho)
	
	player = get_node_or_null("/root/Node2D/player")
	if not player:
		player = get_node_or_null("/root/fase_teste/player")
		
	recalcular_caminho()


func _physics_process(delta: float) -> void:
	if Global.paused or !visible:
		return
	attack_cooldown += delta
	
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# --- ROTAÇÃO E LÓGICA DE KNOCKBACK ---
	# O inimigo sempre encara o jogador, a menos que esteja em knockback.
	if not knockback:
		look_at(player.global_position)
	
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

	# Aplica a força de movimento suavemente
	if direcao_alvo.length() > 0:
		var velocidade_desejada = direcao_alvo * velocidade
		var forca_direcao = velocidade_desejada - velocity
		forca_direcao = forca_direcao.limit_length(forca_maxima_direcao)
		velocity += forca_direcao * delta
		velocity = velocity.limit_length(velocidade)
	else:
		velocity = velocity.lerp(Vector2.ZERO, delta * 3.0)

	move_and_slide()
	update_animation() # Usamos uma função de animação simplificada
	
	# Se o jogador estiver perto, tenta atirar.
	if (player.global_position - global_position).length() < 500:
		shoot()


# --- FUNÇÕES DE LÓGICA ---

func shoot():
	if attack_cooldown >= 3.0:
		var new_bullet = obj_tiro_roxo.instantiate()
		# A direção é simplesmente "para frente" (eixo X positivo) porque o 'look_at' já nos alinhou.
		var direction = Vector2.RIGHT.rotated(global_rotation)
		
		new_bullet.global_position = global_position
		new_bullet.velocity = direction * velocidade_projetil
		get_parent().add_child(new_bullet)
		attack_cooldown = 0.0

func recalcular_caminho() -> void:
	if is_instance_valid(player):
		navigation_agent.target_position = player.global_position

# Função de animação simplificada, sem flip_h.
func update_animation():
	if velocity.length() > 10:
		sprite.play("Walking")
	else:
		sprite.play("Idle")

func aplicar_knockback(direcao: Vector2):
	knockback = true
	tempo_knockback_atual = 0.0
	velocity = direcao * forca_knockback*2/3

func _on_collision_area_body_entered(body: Node2D) -> void:
	if knockback or body == self:
		return
	if body.is_in_group("player"):
		var direcao = (global_position - body.global_position).normalized()
		aplicar_knockback(direcao)
		body.take_damage(5)
