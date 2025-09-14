extends CharacterBody2D
@export var velocidade = 150.0
@onready var sprite: AnimatedSprite2D = $sprite
@export var player = Node2D
const obj_tiro_roxo = preload("res://Cenas/tiro_roxo.tscn")
var timer = 0.0

func _ready() -> void:
	add_to_group("enemies")

func shoot(velocidade_tiro: float):
	if timer >= 1:
		var new_bullet = obj_tiro_roxo.instantiate()
		var direction = (player.position - position).normalized()
		new_bullet.velocity = direction * velocidade_tiro
		new_bullet.position = position
		get_parent().add_child(new_bullet)
		timer = 0.0

func _physics_process(delta: float) -> void:
	timer += get_process_delta_time()
	var direction = (player.position - position).normalized()

	# Move na direção do player
	velocity = direction * velocidade
	var nearby = get_tree().get_nodes_in_group("enemies") + get_tree().get_nodes_in_group("players")
	for other in nearby:
		if other == self:
			continue
		var dist = (other.position - position)
		if dist.length() <= 17:
			position -= velocity * delta * 10
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
		shoot(200)
