extends Area2D
@export var player = Node2D
@export var damage: int = 1
@export var duration: float = 20.0
var velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	# conecta o sinal (pode também conectar no editor)
	connect("body_entered", Callable(self, "_on_body_entered"))

func _process(delta: float) -> void:
	position += velocity * delta

	duration -= delta
	if duration <= 0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	# debug: veja quem entrou
	print("[bullet] body_entered:", body, "is_in_group players?", body.is_in_group("players"))
	if body.is_in_group("players"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()  # destrói a bala ao acertar
