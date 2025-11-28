extends Area2D 

@export var player: Node2D 
@export var damage: int = 1 
@export var speed: float = 130.0 
var timer = 0.0

var velocity: Vector2 = Vector2.ZERO 

func _ready() -> void: 
	connect("body_entered", Callable(self, "_on_body_entered")) 

func _physics_process(delta: float) -> void: 
	if Global.paused:
		return
	timer += delta
	if timer > 5.0: 
		queue_free()
	if not player: 
		return 
	


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
	if body is TileMap or body is TileMapLayer or body is StaticBody2D:
		queue_free()
