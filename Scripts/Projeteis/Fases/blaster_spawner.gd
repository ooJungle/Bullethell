extends Node2D

@export var blaster_scene: PackedScene
@export var spawn_distance: float = 465.0
var player

# Offsets para posicionamento
@export var vertical_offset: float = 2200.0
@export var horizontal_offset: float = 2500.0
@export var player_jitter: float = 75.0

func _ready() -> void:
	# Busca segura do player (tenta pelo grupo primeiro, depois pelo caminho padrão)
	player = get_tree().get_first_node_in_group("players")
	if not player:
		player = get_node_or_null("/root/FaseFinal/player") # Ajuste o caminho se necessário

func spawn_blaster(pattern: String):
	if not is_instance_valid(player):
		return
		
	var blaster = blaster_scene.instantiate()
	
	var spawn_pos: Vector2
	var v_offset = vertical_offset + spawn_distance / 2
	var h_offset = horizontal_offset + spawn_distance / 2

	match pattern:
		"horizontal":
			var x_pos = player.position.x + randf_range(-player_jitter, player_jitter)
			var y_pos
			if randf() < 0.5:
				y_pos = player.position.y - v_offset # Acima
				blaster.rotation_degrees = 90
			else:
				y_pos = player.position.y + v_offset # Abaixo
				blaster.rotation_degrees = 270
			spawn_pos = Vector2(x_pos, y_pos)
			
		"vertical":
			var x_pos
			if randf() < 0.5:
				x_pos = player.position.x - h_offset # Esquerda
				blaster.rotation_degrees = 0
			else:
				x_pos = player.position.x + h_offset # Direita
				blaster.rotation_degrees = 180
			var y_pos = player.position.y + randf_range(-player_jitter, player_jitter)
			spawn_pos = Vector2(x_pos, y_pos)
			
		"diagonal":
			var x_spawn = h_offset * randf_range(0.9, 1.1)
			var y_spawn = v_offset * randf_range(0.9, 1.1)
			var side = randi() % 4
			match side:
				0: # Cima-esquerda
					spawn_pos = player.position + Vector2(-x_spawn, -y_spawn)
					blaster.rotation_degrees = 45
				1: # Cima-direita
					spawn_pos = player.position + Vector2(x_spawn, -y_spawn)
					blaster.rotation_degrees = 135
				2: # Baixo-esquerda
					spawn_pos = player.position + Vector2(-x_spawn, y_spawn)
					blaster.rotation_degrees = 315
				3: # Baixo-direita
					spawn_pos = player.position + Vector2(x_spawn, y_spawn)
					blaster.rotation_degrees = 225
			
		"random":
			var x_pos
			var y_pos
			if randf() < 0.5: # Horizontal
				x_pos = player.position.x + randf_range(-player_jitter, player_jitter)
				if randf() < 0.5:
					y_pos = player.position.y - v_offset
					blaster.rotation_degrees = 90
				else:
					y_pos = player.position.y + v_offset
					blaster.rotation_degrees = 270
			else: # Vertical
				if randf() < 0.5:
					x_pos = player.position.x - h_offset
					blaster.rotation_degrees = 0
				else:
					x_pos = player.position.x + h_offset
					blaster.rotation_degrees = 180
				y_pos = player.position.y + randf_range(-player_jitter, player_jitter)
			spawn_pos = Vector2(x_pos, y_pos)

	blaster.global_position = spawn_pos
	
	add_child(blaster)
	
	if blaster.has_method("iniciar_ataque"):
		blaster.iniciar_ataque()
