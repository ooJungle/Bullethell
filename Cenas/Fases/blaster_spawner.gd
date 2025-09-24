extends Node2D

@export var blaster_scene: PackedScene  # Atribua Blaster.tscn no inspector
@export var spawn_distance: float = 500.0  # Distância fora da tela

var player: Node2D  # Referência local ao player

func _ready():
	# Ajuste este caminho para o seu player (ex.: se a cena root é FaseFinal)
	player = get_parent().get_node("player")
	if not player:
		push_error("BlasterSpawner: Não foi possível encontrar o player! Verifique o caminho.")
		return
	print("BlasterSpawner: Player encontrado em ", player.get_path())

func spawn_blaster(pattern: String):
	if not blaster_scene or not player:
		push_error("BlasterSpawner: Cena do blaster ou player não disponível!")
		return
	
	var blaster = blaster_scene.instantiate() as Node2D
	add_child(blaster)
	
	# Posição de spawn baseada no pattern (fora da tela)
	var spawn_pos: Vector2
	match pattern:
		"horizontal":
			spawn_pos = Vector2(randf_range(-spawn_distance, spawn_distance), -spawn_distance)
		"vertical":
			spawn_pos = Vector2(spawn_distance, randf_range(-250, 250))
		"random":
			spawn_pos = Vector2(randf_range(-spawn_distance, spawn_distance), randf_range(-spawn_distance, spawn_distance))
		_:
			spawn_pos = Vector2(-spawn_distance, 0)  # Default
	
	blaster.global_position = spawn_pos
	blaster.target_player = player
	blaster.shoot_laser()  # Dispara imediatamente ou após delay
