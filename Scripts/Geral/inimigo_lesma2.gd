extends CharacterBody2D

@export var speed = 60.0
@export var forca_gravidade = 2000.0
@export var velocidade_rotacao = 15.0

@onready var ray_cast_2d: RayCast2D = $RayCast2D

func _physics_process(delta):
	velocity.x = speed
	velocity.y += forca_gravidade * delta
	
	var velocidade_final = velocity.rotated(rotation)
	
	velocity = velocidade_final
	
	move_and_slide()
	
	velocity = velocity.rotated(-rotation)
	velocity.x = speed
	
	if (is_on_floor() or is_on_wall() or is_on_ceiling()) and get_slide_collision_count() > 0:
		var normal = get_slide_collision(0).get_normal()
		alinharNormal(normal, delta)
	elif ray_cast_2d.is_colliding():
		var normal = ray_cast_2d.get_collision_normal()
		alinharNormal(normal, delta)
	else:
		rotate(deg_to_rad(velocidade_rotacao * 10) * delta)

func alinharNormal(normal: Vector2, delta: float):
	var target_rotation = normal.angle() + PI / 2
	
	rotation = lerp_angle(rotation, target_rotation, velocidade_rotacao * delta)
