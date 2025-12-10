extends CharacterBody2D

# --- Variáveis de Movimento e Combate ---
@export var velocidade = 100.0 # Velocidade MÁXIMA BASE
@export var player: CharacterBody2D
@export var forca_maxima_direcao = 200.0 # Aceleração/Curva
@export var forca_knockback = 450.0

# --- Nós Filhos ---
@onready var sprite: AnimatedSprite2D = $sprite
@onready var navigation_agent := $NavigationAgent2D as NavigationAgent2D
@onready var area_deteccao: Area2D = $Area2D
@onready var perception_timer: Timer = $PerceptionTimer

# --- Disparos ---
const obj_tiro_verde = preload("res://Cenas/Projeteis/tiro_verde.tscn")
var timer = 0.0

var knockback = false
var tempo_knockback = 0.0

func _ready() -> void:
	add_to_group("enemies")
	
	perception_timer.wait_time = 0.5
	perception_timer.timeout.connect(makepath)
	perception_timer.start()
	
	player = get_node_or_null("/root/Node2D/player")
	if not player:
		player = get_node_or_null("/root/fase_teste/player")
		
	call_deferred("makepath")

func _physics_process(delta: float) -> void:
	if Global.paused or !visible:
		return
	
	timer += delta * Global.fator_tempo
	
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if knockback:
		tempo_knockback += delta
		if tempo_knockback >= 0.4:
			knockback = false
		velocity = velocity.lerp(Vector2.ZERO, delta * 5.0 * Global.fator_tempo)
		move_and_slide()
		return

	var direcao_alvo = Vector2.ZERO
	
	if not navigation_agent.is_navigation_finished():
		var next_path_position = navigation_agent.get_next_path_position()
		direcao_alvo = global_position.direction_to(next_path_position)

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


func makepath() -> void:
	if is_instance_valid(player):
		# Define o destino do agente como a posição do player.
		# O NavigationAgent cuidará de calcular como chegar lá desviando das paredes.
		navigation_agent.target_position = player.global_position

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
	velocity = direcao * forca_knockback*2/3

func _on_collision_area_body_entered(body: Node2D) -> void:
	if knockback or body == self:
		return
	if body.is_in_group("player"):
		var direcao = (global_position - body.global_position).normalized()
		aplicar_knockback(direcao)

func shoot():
	if timer >= 4:
		var new_bullet = obj_tiro_verde.instantiate()
		var direction = (player.global_position - global_position).normalized()
		new_bullet.player = player
		new_bullet.global_position = global_position
		new_bullet.velocity = direction * 150 
		get_parent().add_child(new_bullet)
		timer = 0.0

func take_damage(_amount: int) -> void:	
	queue_free()
