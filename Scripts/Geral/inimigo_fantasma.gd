extends CharacterBody2D

@export var velocidade = 150.0 
@export var player: CharacterBody2D
@export var forca_knockback = 600.0 
@export var tempo_vida_maximo: float = 30.0

const obj_tiro_azul = preload("res://Cenas/Projeteis/tiro_azul.tscn")

@onready var sprite: AnimatedSprite2D = $sprite
@onready var collision_area: Area2D = $CollisionArea

var shoot_timer = 0.0
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

	shoot_timer += delta * Global.fator_tempo
	
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

	var direcao = (player.global_position - global_position).normalized()
	velocity = direcao * velocidade * Global.fator_tempo

	move_and_slide()
	
	update_animation_and_flip()
	
	if (player.global_position - global_position).length() < 500:
		shoot()

func shoot():
	if shoot_timer >= 1.2:
		var new_bullet = obj_tiro_azul.instantiate()
		new_bullet.position = global_position
		get_parent().add_child(new_bullet)
		shoot_timer = 0.0

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

func take_damage(_amount: int) -> void:
	queue_free()
