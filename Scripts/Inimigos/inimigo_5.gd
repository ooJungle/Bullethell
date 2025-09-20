extends CharacterBody2D



# --- Variáveis de Movimento e Combate ---

@export var velocidade = 100.0 # Representa a velocidade MÁXIMA

@export var player: Node2D

@export var forca_maxima_direcao = 200.0 # Quão rápido o inimigo pode virar.

@export var forca_knockback = 450.0



# --- Nós Filhos ---

@onready var sprite: AnimatedSprite2D = $sprite

@onready var navigation_agent := $NavigationAgent2D as NavigationAgent2D

@onready var area_deteccao: Area2D = $Area2D

@onready var perception_timer: Timer = $PerceptionTimer



# --- Disparos ---

const obj_tiro_azul = preload("res://Cenas/Projeteis/tiro_azul.tscn")

var timer = 0.0



# --- Knockback ---

var knockback = false

var tempo_knockback = 0.0





func _ready() -> void:

	add_to_group("enemies")

	perception_timer.timeout.connect(makepath)

	area_deteccao.body_entered.connect(_on_area_2d_body_entered)

	makepath()





func _physics_process(delta: float) -> void:

	if Global.paused:

		return



	timer += delta

	if not is_instance_valid(player):

		velocity = Vector2.ZERO

		move_and_slide()

		return



	if knockback:

		tempo_knockback += delta

		if tempo_knockback >= 0.4:

			knockback = false

		velocity = velocity.lerp(Vector2.ZERO, delta * 5.0)

		move_and_slide()

		return



	# --- LÓGICA DE MOVIMENTO COM STEERING FORCE (SEM RAYCASTS) ---

	var direcao_alvo = Vector2.ZERO

	if not navigation_agent.is_navigation_finished():

		# A direção desejada é simplesmente a direção para o próximo ponto do caminho do GPS.

		direcao_alvo = global_position.direction_to(navigation_agent.get_next_path_position())



	if direcao_alvo.length() > 0:

		var velocidade_desejada = direcao_alvo * velocidade



		# Calcula-se a Força de Direção (Steering Force).

		var forca_direcao = velocidade_desejada - velocity



		# Limita-se a força para que a viragem não seja instantânea.

		forca_direcao = forca_direcao.limit_length(forca_maxima_direcao)



		# Aplica-se a força como uma aceleração.

		velocity += forca_direcao * delta



		# Garante-se que a velocidade final não ultrapassa a velocidade máxima.

		velocity = velocity.limit_length(velocidade)

	else:

		# Se não há caminho, desacelera suavemente.

		velocity = velocity.lerp(Vector2.ZERO, delta * 3.0)



	move_and_slide()



	update_animation_and_flip()



	if is_instance_valid(player) and (player.global_position - global_position).length() < 500:

		shoot()





func makepath() -> void:

	if is_instance_valid(player):

		navigation_agent.target_position = Vector2(player.global_position.x - randi_range(-25, 25), player.global_position.y  - randi_range(-25, 25)) 







func update_animation_and_flip():

	if velocity.length() > 10:

		sprite.play("Walking")

		if velocity.x > 0:

			sprite.flip_h = false

		elif velocity.x < 0:

			sprite.flip_h = true

	else:

		sprite.play("Idle")





func aplicar_knockback(direcao: Vector2):

	knockback = true

	tempo_knockback = 0.0

	velocity = direcao * forca_knockback





func _on_area_2d_body_entered(body: Node2D) -> void:

	if body == self:

		return



	if knockback:

		return



	if body.is_in_group("players"):

		var direcao = (global_position - body.global_position).normalized()

		aplicar_knockback(direcao)





func shoot():

	if timer >= 4:

		var new_bullet = obj_tiro_azul.instantiate()

		var direction = (player.global_position - global_position).normalized()

		new_bullet.player = player

		new_bullet.global_position = global_position

		new_bullet.velocity = direction * velocidade * 1.5

		get_parent().add_child(new_bullet)

		timer = 0.0
