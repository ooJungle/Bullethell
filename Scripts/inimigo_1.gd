extends CharacterBody2D
@export var velocidade = 150.0
@onready var sprite: AnimatedSprite2D = $sprite
@export var player = Node2D
const obj_tiro_azul = preload("res://Cenas/tiro_azul.tscn")
var timer = 0.0

func shoot():
	if timer >= 1.2:
		var new_bullet = obj_tiro_azul.instantiate()
		var direction = (player.position - position).normalized()
		
		new_bullet.player = player
		new_bullet.position = position
		new_bullet.velocity = direction * velocidade
		get_parent().add_child(new_bullet)
		timer = 0.0

func _process(_delta: float) -> void:
	timer += get_process_delta_time()
	var direction = (player.position - position).normalized()
	# Move na direção do player
	velocity = direction * velocidade
	move_and_slide()

	# Flip do sprite
	if velocity.x > 0:
		sprite.flip_h = false
	elif velocity.x < 0:
		sprite.flip_h = true
	
	# Animação (opcional)
	if velocity.length() > 0:
		sprite.play("Walking")
	else:
		sprite.play("Idle")
		
	if (player.position - position).length() < 200:
		shoot()
	var nearby = get_tree().get_nodes_in_group("enemies") + get_tree().get_nodes_in_group("players")
	for other in nearby:
		if other == self:
			continue
		var dist = position.distance_to(other.position)
		if dist < 16:
			velocity += (position - other.position).normalized() * 50
