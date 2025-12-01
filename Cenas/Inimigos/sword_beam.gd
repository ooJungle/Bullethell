extends Node2D

@onready var Area_1: Area2D = $Area1
@onready var Area_2: Area2D = $Area2

var damage = 2
var speed = 400
var direction = Vector2.RIGHT

func _ready():
	var notifier = VisibleOnScreenNotifier2D.new()
	add_child(notifier)
	notifier.screen_exited.connect(queue_free)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta * Global.fator_tempo
	var corpos_area_1 = Area_1.get_overlapping_bodies()
	var corpos_area_2 = Area_2.get_overlapping_bodies()
	
	var todos_corpos = corpos_area_1 + corpos_area_2
	
	for body in todos_corpos:
		tratar_dano(body)

	for body in corpos_area_1:
		if body in corpos_area_2:
			
			if body is TileMap or body is TileMapLayer or body is StaticBody2D:
				queue_free()
				return

func tratar_dano(body):
	if body.is_in_group("players"):
		return

	if body.is_in_group("inimigo") or body.is_in_group("boss"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
			
	if body.is_in_group("cristais"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
			queue_free()
