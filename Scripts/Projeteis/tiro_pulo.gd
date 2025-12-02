extends Area2D
@export var player = Node2D
@export var damage: int = 1
@export var duration: float = 6.0
var velocity: Vector2 = Vector2.ZERO

@onready var sprite: AnimatedSprite2D = $sprite

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	sprite.animation = "variacoes"
	sprite.pause()
	var total_frames = sprite.sprite_frames.get_frame_count(sprite.animation)
	var frame_aleatorio = randi() % total_frames
	sprite.frame = frame_aleatorio

func _process(delta: float) -> void:
	if Global.paused:
		return
	position += velocity * delta  * Global.fator_tempo

	duration -= delta
	if duration <= 0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("players"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
	if body is TileMap or body is TileMapLayer or body is StaticBody2D:
		queue_free()
