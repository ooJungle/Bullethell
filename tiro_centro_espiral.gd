extends Area2D
@export var player = Node2D
@export var duration: float = 5.0
@onready var centro = $centro
var velocity: Vector2 = Vector2.ZERO
var rotacao = 90.0
const obj_tiro_roxo = preload("res://Cenas/tiro_roxo.tscn")

func _ready() -> void:
	# conecta o sinal (pode também conectar no editor)
	connect("body_entered", Callable(self, "_on_body_entered"))

func _process(delta: float) -> void:
	position += velocity * delta
	centro.rotation_degrees += rotacao * delta
	duration -= delta
	if duration <= 0:
		queue_free()
