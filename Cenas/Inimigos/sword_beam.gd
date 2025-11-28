extends Area2D

@export var speed: float = 600.0
@export var damage: int = 10
var direction: Vector2 = Vector2.RIGHT

func _ready():
	body_entered.connect(_on_body_entered)
	var notifier = VisibleOnScreenNotifier2D.new()
	add_child(notifier)
	notifier.screen_exited.connect(queue_free)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta * Global.fator_tempo

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		return
		
	if body.is_in_group("inimigo") or body.is_in_group("boss"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
	if body.is_in_group("cristais"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
			queue_free() 

	
	elif body is TileMap or body is TileMapLayer or body is StaticBody2D:
		queue_free()
