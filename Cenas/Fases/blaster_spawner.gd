extends Node2D

@export var blaster_scene: PackedScene  # Atribua Blaster.tscn no inspector
@export var spawn_distance: float = 475.0  # Distância fora da tela
var player

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")

func spawn_blaster(pattern: String):
	var blaster = blaster_scene.instantiate()
	add_child(blaster)
	
	# Posição de spawn baseada no pattern (fora da tela)
	var spawn_pos: Vector2
	var orientation: String = "horizontal"
	match pattern:
		"horizontal":
			orientation = "horizontal"
			# Spawna em cima ou embaixo, com X aleatório
			var x_pos = player.position.x + randf_range(-50, 50)
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
			# Spawna na esquerda ou na direita, com Y aleatório
			var x_pos
			if randf() < 0.5:
				x_pos = -spawn_distance
				blaster.rotation_degrees = 0
			else:
				x_pos = spawn_distance
				blaster.rotation_degrees = 180
			var y_pos = player.position.y + randf_range(-50, 50)
			spawn_pos = Vector2(x_pos, y_pos)
			
		"random":
			# Escolhe aleatoriamente entre um spawn horizontal ou vertical
			var x_pos
			var y_pos
			if randf() < 0.5:
				orientation = "horizontal"
				x_pos = player.position.x + randf_range(-50, 50)
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
				y_pos = player.position.y + randf_range(-50, 50)
			spawn_pos = Vector2(x_pos, y_pos)

	blaster.global_position = spawn_pos
	blaster.set_orientation(orientation)
