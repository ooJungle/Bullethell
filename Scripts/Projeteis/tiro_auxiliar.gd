extends Area2D

@export var damage: int = 1

func _ready() -> void:
	# conecta o sinal (pode também conectar no editor)
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	# debug: veja quem entrou
	if body.is_in_group("players"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()  # destrói a bala ao acertar
	if body.name == "TileMapLayer":
		queue_free()
