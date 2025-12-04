extends Area2D
@export var player = Node2D
@export var damage: int = 1
@export var duration: float = 10.0
var velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))

func _process(delta: float) -> void:
	if Global.paused:
		return
	position += velocity * delta  * Global.fator_tempo

	duration -= delta
	if duration <= 0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(0,damage, 0)
		queue_free()
	if body is TileMap or body is TileMapLayer or body is StaticBody2D:
		queue_free()
