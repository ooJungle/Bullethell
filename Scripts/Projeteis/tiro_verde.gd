extends Area2D 

@export var player: Node2D
@export var damage: int = 1
@export var speed: float = 130.0
@export var duration: float = 5.0
@export var steering_strength: float = 5.0  # quanto mais alto, mais rápido a bala ajusta a direção

var velocity: Vector2 = Vector2.ZERO
var timer = 0.0

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))

func _physics_process(delta: float) -> void:
	if Global.paused:
		return
	timer += delta
	if not player:
		return

	# --- Steering Behavior ---
	var desired_velocity = (player.position - position).normalized() * speed
	var steering_force = desired_velocity - velocity
	velocity += steering_force * steering_strength * delta * Global.fator_tempo

	# Move manual (Area2D não tem move_and_slide)
	position += velocity * delta * Global.fator_tempo

	# Timer da bala
	duration -= delta
	if duration <= 0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("players"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
