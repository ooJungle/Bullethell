extends Node2D

@export var blaster_scene: PackedScene
@export var spawn_distance: float = 465.0
var player

@export var vertical_offset: float = 2200.0
@export var horizontal_offset: float = 2500.0
@export var player_jitter: float = 75.0

func _ready() -> void:
	player = get_node_or_null("/root/Node2D/player")
	
func spawn_blaster(pattern: String):
	# Garantia de que o player foi encontrado
	if not is_instance_valid(player):
		print("ERRO: Player não encontrado. O Blaster não pode ser spawnado.")
		return
		
	var blaster = blaster_scene.instantiate()
	add_child(blaster)
	
	var spawn_pos: Vector2
	var orientation: String = "horizontal"
	
	# Calcula os offsets reais,
	# mantendo sua lógica original de somar o spawn_distance
	var v_offset = vertical_offset + spawn_distance / 2
	var h_offset = horizontal_offset + spawn_distance / 2

	match pattern:
		"horizontal":
			orientation = "horizontal"
			var x_pos = player.position.x + randf_range(-player_jitter, player_jitter)
			var y_pos
			if randf() < 0.5:
				y_pos = player.position.y - v_offset # Acima do player
				blaster.rotation_degrees = 90
			else:
				y_pos = player.position.y + v_offset # Abaixo do player
				blaster.rotation_degrees = 270
			spawn_pos = Vector2(x_pos, y_pos)
			
		"vertical":
			orientation = "vertical"
			var x_pos
			if randf() < 0.5:
				x_pos = player.position.x - h_offset # Esquerda do player
				blaster.rotation_degrees = 0
			else:
				x_pos = player.position.x + h_offset # Direita do player
				blaster.rotation_degrees = 180
			var y_pos = player.position.y + randf_range(-player_jitter, player_jitter)
			spawn_pos = Vector2(x_pos, y_pos)
			
		"diagonal":
			orientation = "diagonal"
			# Usar os mesmos offsets para criar os "cantos" relativos ao player
			var x_spawn = h_offset * randf_range(0.9, 1.1) # Um pouco de variação
			var y_spawn = v_offset * randf_range(0.9, 1.1) # Um pouco de variação
			
			var side = randi() % 4
			match side:
				0:  # Cima-esquerda
					spawn_pos = player.position + Vector2(-x_spawn, -y_spawn)
					blaster.rotation_degrees = 45
				1:  # Cima-direita
					spawn_pos = player.position + Vector2(x_spawn, -y_spawn)
					blaster.rotation_degrees = 135
				2:  # Baixo-esquerda
					spawn_pos = player.position + Vector2(-x_spawn, y_spawn)
					blaster.rotation_degrees = 315
				3:  # Baixo-direita
					spawn_pos = player.position + Vector2(x_spawn, y_spawn)
					blaster.rotation_degrees = 225
			
		"random":
			# A lógica duplicada aqui também precisa ser corrigida
			var x_pos
			var y_pos
			if randf() < 0.5:
				orientation = "horizontal"
				x_pos = player.position.x + randf_range(-player_jitter, player_jitter)
				if randf() < 0.5:
					y_pos = player.position.y - v_offset # Acima
					blaster.rotation_degrees = 90
				else:
					y_pos = player.position.y + v_offset # Abaixo
					blaster.rotation_degrees = 270
			else:
				orientation = "vertical"
				if randf() < 0.5:
					x_pos = player.position.x - h_offset # Esquerda
					blaster.rotation_degrees = 0
				else:
					x_pos = player.position.x + h_offset # Direita
					blaster.rotation_degrees = 180
				y_pos = player.position.y + randf_range(-player_jitter, player_jitter)
			spawn_pos = Vector2(x_pos, y_pos)

	blaster.global_position = spawn_pos
