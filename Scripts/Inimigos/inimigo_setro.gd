extends CharacterBody2D

@export var velocidade = 90.0
@export var forca_maxima_direcao = 180.0
@export var tempo_percepcao = 0.5

@export var player: CharacterBody2D
@export var forca_knockback = 600.0
@export var velocidade_projetil = 130.0
@export var tempo_vida_maximo: float = 30.0

const obj_tiro_roxo = preload("res://Cenas/Projeteis/tiro_roxo.tscn")
const obj_tiro_azul = preload("res://Cenas/Projeteis/tiro_azul.tscn")
const obj_tiro_verde = preload("res://Cenas/Projeteis/tiro_verde.tscn")

@onready var sprite: AnimatedSprite2D = $sprite
@onready var collision_area: Area2D = $CollisionArea

var ataque_aleatorio = 0
var attack_cooldown = 0.0
var tempo_entre_tiros = 0.0
var limite_projeteis = 0
var rotacao_ataque = 200.0
var atirando = false
var direcao_ataque_fixa: Vector2 = Vector2.ZERO

var knockback = false
var tempo_knockback_atual = 0.0
var tempo_vida_atual: float = 0.0

func _ready() -> void:
	add_to_group("inimigo")
	
	player = get_node_or_null("/root/Node2D/player")
	if not player:
		player = get_node_or_null("/root/fase_teste/player")

func _physics_process(delta: float) -> void:
	if Global.paused or !visible:
		return
	
	tempo_vida_atual += delta * Global.fator_tempo
	if tempo_vida_atual >= tempo_vida_maximo:
		queue_free()
		return

	attack_cooldown += delta * Global.fator_tempo
	tempo_entre_tiros += delta * Global.fator_tempo
	
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if knockback:
		tempo_knockback_atual += delta
		if tempo_knockback_atual >= 0.3:
			knockback = false
		velocity = velocity.lerp(Vector2.ZERO, delta * 5.0)
		move_and_slide()
		return

	if not atirando:
		var direcao = (player.global_position - global_position).normalized()
		velocity = direcao * velocidade * Global.fator_tempo
	else:
		velocity = velocity.lerp(Vector2.ZERO, delta * 5.0 * Global.fator_tempo)

	move_and_slide()
	update_animation_and_flip()
	
	if (player.global_position - global_position).length() < 500:
		shoot()

func shoot():
	if ataque_aleatorio == 0:
		if not atirando:
			direcao_ataque_fixa = (player.global_position - global_position).normalized()
		if attack_cooldown >= 3:
			atirando = true
			if tempo_entre_tiros > 0.01:
				rotacao_ataque += 0.1
				var new_bullet = obj_tiro_roxo.instantiate()
				new_bullet.global_position = global_position
				new_bullet.velocity = (direcao_ataque_fixa * velocidade_projetil).rotated(rotacao_ataque)
				get_parent().add_child(new_bullet)
				limite_projeteis += 1
				tempo_entre_tiros = 0.0
			if limite_projeteis > 30:
				attack_cooldown = 0.0
				limite_projeteis = 0
				rotacao_ataque = 200.0
				atirando = false
				ataque_aleatorio = randi_range(0, 4)

	if ataque_aleatorio == 1:
		if attack_cooldown >= 3:
			for i in range(11):
				var new_bullet = obj_tiro_roxo.instantiate()
				var direction = (player.global_position - global_position).normalized().rotated(deg_to_rad(360.0 / 11.0 * i))
				new_bullet.global_position = global_position
				new_bullet.velocity = direction * velocidade_projetil
				get_parent().add_child(new_bullet)
			attack_cooldown = 0.0
			ataque_aleatorio = randi_range(0, 4)

	if ataque_aleatorio == 2:
		if attack_cooldown >= 3:
			var new_bullet = obj_tiro_roxo.instantiate()
			var direction = (player.global_position - global_position).normalized()
			new_bullet.global_position = global_position
			new_bullet.velocity = direction * velocidade_projetil
			get_parent().add_child(new_bullet)
			attack_cooldown = 0.0
			ataque_aleatorio = randi_range(0, 4)

	if ataque_aleatorio == 3:
		if attack_cooldown >= 3:
			var new_bullet = obj_tiro_azul.instantiate()
			var direction = (player.global_position - global_position).normalized()
			new_bullet.player = player
			new_bullet.global_position = global_position
			new_bullet.velocity = direction * velocidade_projetil
			get_parent().add_child(new_bullet)
			attack_cooldown = 0.0
			ataque_aleatorio = randi_range(0, 4)

	if ataque_aleatorio == 4:
		if attack_cooldown >= 3:
			for i in range(4):
				var new_bullet = obj_tiro_verde.instantiate()
				var direction = (player.global_position - global_position).normalized()
				new_bullet.player = player
				new_bullet.global_position = global_position
				new_bullet.velocity = direction * velocidade_projetil
				get_parent().add_child(new_bullet)
			attack_cooldown = 0.0
			ataque_aleatorio = randi_range(0, 4)

func update_animation_and_flip():
	if velocity.length() > 10:
		sprite.play("Walking")
		if velocity.x > 0: sprite.flip_h = false
		elif velocity.x < 0: sprite.flip_h = true
	else:
		sprite.play("Idle")

func aplicar_knockback(direcao: Vector2):
	knockback = true
	tempo_knockback_atual = 0.0
	velocity = direcao * forca_knockback*2

func _on_collision_area_body_entered(body: Node2D) -> void:
	if knockback or body == self:
		return
	if body.is_in_group("player"):
		var direcao = (global_position - body.global_position).normalized()
		aplicar_knockback(direcao)
		body.take_damage(5)

func take_damage(amount: int) -> void:	
	queue_free()
