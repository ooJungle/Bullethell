extends Area2D

@export var damage: int = 1

func _ready() -> void:
	# conecta o sinal (pode também conectar no editor)
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("players"):
		Global.vida -= 1
		Global.Tomou_ano()
		queue_free()
	if body.name == "TileMapLayer":
		queue_free()
