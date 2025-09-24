extends Node2D

@export var blaster_scene: PackedScene  # Atribua Blaster.tscn no inspector
@export var spawn_distance: float = 475.0  # Distância fora da tela

var player: Node2D  # Referência local ao player

func _ready():
	# Ajuste este caminho para o seu player (ex.: se a cena root é FaseFinal)
	player = get_parent().get_node("player")
	if not player:
		push_error("BlasterSpawner: Não foi possível encontrar o player! Verifique o caminho.")
		return
	print("BlasterSpawner: Player encontrado em ", player.get_path())

func spawn_blaster(pattern: String):
	var blaster = blaster_scene.instantiate() as Node2D
	add_child(blaster)
	
	# Posição de spawn baseada no pattern (fora da tela)
	var spawn_pos: Vector2
	match pattern:
		"horizontal":
			if randf_range(0, 1) >= 0.5:
				spawn_pos = Vector2(randf_range(-spawn_distance, spawn_distance), -275)
			else:
				spawn_pos = Vector2(randf_range(-spawn_distance, spawn_distance), 275)
		"vertical":
			if randf_range(0, 1) >= 0.5:
				spawn_pos = Vector2(spawn_distance, -275)
			else:
				spawn_pos = Vector2(spawn_distance, 275)
		"random":
			if randf_range(0, 1) >= 0.5:
				spawn_pos = Vector2(randf_range(-spawn_distance, spawn_distance), -275)
			else:
				spawn_pos = Vector2(randf_range(-spawn_distance, spawn_distance), 275)
		_:
			spawn_pos = Vector2(-spawn_distance, 0)  # Default
	
	blaster.global_position = spawn_pos
	blaster.target_player = player
