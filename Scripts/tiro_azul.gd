extends Area2D

@export var player: Node2D
@export var damage: int = 1
@export var speed: float = 175.0
@export var duration: float = 5.0
@export var timer = 0.0

var velocity: Vector2 = Vector2.ZERO
func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))

func _physics_process(delta: float) -> void:
	timer += delta
	if not player:
		return
	if timer <= 1:
		var direction = (player.position - position).normalized()
		velocity = direction * speed
		# Move manual (Area2D não tem move_and_slide)
		position += velocity * delta
	else:
		position += velocity * delta

	# Timer da bala
	duration -= delta
	if duration <= 0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	print("[bullet] body_entered:", body, "is_in_group players?", body.is_in_group("players"))
	if body.is_in_group("players"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
