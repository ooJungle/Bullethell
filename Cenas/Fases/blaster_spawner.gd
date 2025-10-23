extends Node2D

@export var blaster_scene: PackedScene
@export var spawn_distance: float = 465.0
var player

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	player.speed = 100
	
func spawn_blaster(pattern: String):
	var blaster = blaster_scene.instantiate()
	add_child(blaster)
	
	# Posição de spawn baseada no pattern (fora da tela)
	var spawn_pos: Vector2
	var orientation: String = "horizontal"
	match pattern:
		"horizontal":
			orientation = "horizontal"
			var x_pos = player.position.x + randf_range(-75, 75)
			var y_pos
			if randf() < 0.5:
				y_pos = -spawn_distance/2 
				blaster.rotation_degrees = 90
			else:
				y_pos = spawn_distance/2
				blaster.rotation_degrees = 270
			spawn_pos = Vector2(x_pos, y_pos)
			
		"vertical":
			orientation = "vertical"
			var x_pos
			if randf() < 0.5:
				x_pos = -spawn_distance
				blaster.rotation_degrees = 0
			else:
				x_pos = spawn_distance
				blaster.rotation_degrees = 180
			var y_pos = player.position.y + randf_range(-75, 75)
			spawn_pos = Vector2(x_pos, y_pos)
			
		"diagonal":
			orientation = "diagonal"
			var start_diagonal_distance = spawn_distance * 0.3
			var end_diagonal_distance = spawn_distance * 1.1
			var side = randi() % 4
			match side:
				0:  # Cima-esquerda
					spawn_pos = Vector2(-randf_range(start_diagonal_distance, end_diagonal_distance), -(start_diagonal_distance+end_diagonal_distance)/2)
					blaster.rotation_degrees = 45
				1:  # Cima-direita
					spawn_pos = Vector2(randf_range(start_diagonal_distance, end_diagonal_distance), -(start_diagonal_distance+end_diagonal_distance)/2)
					blaster.rotation_degrees = 135
				2:  # Baixo-esquerda
					spawn_pos = Vector2(-randf_range(start_diagonal_distance, end_diagonal_distance), (start_diagonal_distance+end_diagonal_distance)/2)
					blaster.rotation_degrees = 315
				3:  # Baixo-direita
					spawn_pos = Vector2(randf_range(start_diagonal_distance, end_diagonal_distance), (start_diagonal_distance+end_diagonal_distance)/2)
					blaster.rotation_degrees = 225
			
		"random":
			var x_pos
			var y_pos
			if randf() < 0.5:
				orientation = "horizontal"
				x_pos = player.position.x + randf_range(-75, 75)
				if randf() < 0.5:
					y_pos = -spawn_distance/2 
					blaster.rotation_degrees = 90
				else:
					y_pos = spawn_distance/2
					blaster.rotation_degrees = 270
			else:
				orientation = "vertical"
				if randf() < 0.5:
					x_pos = -spawn_distance
					blaster.rotation_degrees = 0
				else:
					x_pos = spawn_distance
					blaster.rotation_degrees = 180
				y_pos = player.position.y + randf_range(-75, 75)
			spawn_pos = Vector2(x_pos, y_pos)

	blaster.global_position = spawn_pos
	blaster.set_orientation(orientation)
