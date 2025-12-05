extends CharacterBody2D

# --- Variáveis de Movimento e Percepção ---
@export var velocidade = 90.0
@export var forca_maxima_direcao = 180.0
@export var tempo_percepcao = 0.5
var timer: float = 0.0

# --- Variáveis de Combate ---
@export var player: CharacterBody2D
@export var forca_knockback = 600.0
@export var velocidade_projetil = 130.0
# MANTIDO O SEU PRELOAD ORIGINAL:
const obj_tiro_cabeca = preload("uid://c1jmoiulli385")

# --- Nós Filhos ---
@onready var sprite: AnimatedSprite2D = $sprite
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var perception_timer: Timer = $PerceptionTimer
@onready var collision_area: Area2D = $CollisionArea

# --- Variáveis de Estado ---
var attack_cooldown = 0.0
var knockback = false
var tempo_knockback_atual = 0.0
var is_shooting_anim = false 

func _ready() -> void:
	add_to_group("enemies")
	
	perception_timer.wait_time = tempo_percepcao
	perception_timer.timeout.connect(recalcular_caminho)
		
	player = get_node_or_null("/root/Node2D/player")
	if not player:
		player = get_node_or_null("/root/fase_teste/player")
		
	recalcular_caminho()


func _physics_process(delta: float) -> void:
	timer += delta
	if timer >= 15:
		take_damage(1)
	if Global.paused or !visible:
		return
	attack_cooldown += delta

	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	look_at(player.global_position)
	rotation_degrees -= 90
	if knockback:
		tempo_knockback_atual += delta
		if tempo_knockback_atual >= 0.3:
			knockback = false
		velocity = velocity.lerp(Vector2.ZERO, delta * 5.0)
		move_and_slide()
		return

	var direcao_alvo = Vector2.ZERO
	if not navigation_agent.is_navigation_finished():
		direcao_alvo = global_position.direction_to(navigation_agent.get_next_path_position())

	if direcao_alvo.length() > 0:
		var velocidade_desejada = direcao_alvo * velocidade
		var forca_direcao = velocidade_desejada - velocity
		forca_direcao = forca_direcao.limit_length(forca_maxima_direcao)
		velocity += forca_direcao * delta
		velocity = velocity.limit_length(velocidade)
	else:
		velocity = velocity.lerp(Vector2.ZERO, delta * 3.0)

	move_and_slide()

	if (player.global_position - global_position).length() < 500:
		shoot()

func shoot():
	sprite.play("tiro")
	if attack_cooldown >= 3.0:
		for i in range(-1, 2):
			var new_bullet = obj_tiro_cabeca.instantiate()
			new_bullet.global_position = global_position
			
			var base_direction = Vector2.DOWN
			if is_instance_valid(player):
				base_direction = (player.global_position - global_position).normalized()
			var angle_offset = deg_to_rad(i * 5)
			var final_direction = base_direction.rotated(angle_offset)
			new_bullet.velocity = final_direction * velocidade_projetil
			get_parent().add_child(new_bullet)
		attack_cooldown = 0.0

func recalcular_caminho() -> void:
	if is_instance_valid(player):
		navigation_agent.target_position = player.global_position

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

func take_damage(_amount: int) -> void:	
	Global.inimigo_morreu.emit()
	queue_free()
