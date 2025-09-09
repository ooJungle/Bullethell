extends CharacterBody2D


@export var speed = 300.0
@onready var sprite: AnimatedSprite2D = $sprite
var direction : Vector2


func _physics_process(delta: float) -> void:
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")
	if direction.x > 0: sprite.flip_h = false
	elif direction.x < 0: sprite.flip_h = true

	if direction:
		velocity = direction * speed
		if sprite.animation != "Walking": sprite.animation = "Walking"
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed)
		if sprite.animation != "Idle": sprite.animation = "Idle"
	move_and_slide()
