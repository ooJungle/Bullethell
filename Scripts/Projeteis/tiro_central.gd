extends Area2D
@export var player = Node2D
@export var duration: float = 2.0
@onready var centro = $centro
var velocity: Vector2 = Vector2.ZERO
var rotacao = 120.0

func _ready() -> void:
	# conecta o sinal (pode também conectar no editor)
	connect("body_entered", Callable(self, "_on_body_entered"))

func _process(delta: float) -> void:
	position += velocity * delta  * Global.fator_tempo
	centro.rotation_degrees += rotacao * delta  * Global.fator_tempo
	duration -= delta
	if duration <= 0:
		queue_free()
