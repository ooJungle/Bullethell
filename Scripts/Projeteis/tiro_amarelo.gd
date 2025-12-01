extends CharacterBody2D

@export var damage: int = 1
@export var duration: float = 10.0
@export var speed: float = 500.0
@export var max_bounces: int = 1000

func _ready() -> void:
	if velocity == Vector2.ZERO:
		velocity = Vector2.RIGHT.rotated(rotation) * speed

func _physics_process(delta: float) -> void:
	var collision_info = move_and_collide(velocity * delta)
	
	if collision_info:
		var collider = collision_info.get_collider()
		
		if collider.is_in_group("player"):
			if collider.has_method("take_damage"):
				collider.take_damage(damage)
			queue_free()
			return

		if max_bounces > 0:
			velocity = velocity.bounce(collision_info.get_normal())
			rotation = velocity.angle()
			max_bounces -= 1
		else:
			queue_free()

	duration -= delta
	if duration <= 0:
		queue_free()
