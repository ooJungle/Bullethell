extends Node2D

# --- REFERÊNCIAS ---
@onready var player: CharacterBody2D # Será buscado no _ready
@export var nav_region: NavigationRegion2D
@export var tilemap: TileMapLayer # Arraste o TileMapLayer aqui no Inspector

# --- LISTA DE INIMIGOS ---
var enemies_list = [
	{"path": "res://Cenas/Inimigos/inimigo_pulo_2.tscn", "weight": 10},
	{"path": "res://Cenas/Inimigos/inimigo_polvo_2.tscn", "weight": 10},
	{"path": "res://Cenas/Inimigos/inimigo_cabeca_2.tscn", "weight": 10}
]

# --- VARIÁVEIS DE MAPA E SPAWN ---
var map_left: float = -100000
var map_right: float = 100000
var map_top: float = -100000
var map_bottom: float = 100000
var spawn_position: Vector2

func _ready() -> void:
	# 1. Busca o Player
	player = get_tree().get_first_node_in_group("players")
	
	# 2. Calcula os limites do mapa automaticamente (se houver TileMap)
	if tilemap:
		var used_rect = tilemap.get_used_rect()
		var cell_size = tilemap.tile_set.tile_size if tilemap.tile_set else Vector2(16, 16)
		
		# Converte coordenadas de tile para pixels globais
		var top_left = tilemap.to_global(tilemap.map_to_local(used_rect.position))
		var bottom_right_pos = used_rect.position + used_rect.size
		var bottom_right = tilemap.to_global(tilemap.map_to_local(bottom_right_pos))
		
		# Ajusta os limites (com uma margem interna se quiser)
		map_left = top_left.x
		map_top = top_left.y
		map_right = bottom_right.x
		map_bottom = bottom_right.y
		
		print("Limites da Fase definidos: ", map_left, map_top, map_right, map_bottom)
	else:
		print("AVISO: TileMap não atribuído. Limites de spawn infinitos.")

# --- FUNÇÕES DE ONDA (CHAMADAS PELO NPC) ---

func spawnar_onda_por_escolha(quantidade: int):
	print("Consequência da Escolha: Spawnando ", quantidade, " inimigos!")
	
	for i in range(quantidade):
		# 1. Escolhe um inimigo aleatório da lista
		if enemies_list.is_empty(): return
		
		var dados_inimigo = enemies_list.pick_random()
		var path = dados_inimigo["path"]
		
		# 2. Spawna usando a lógica de posição segura
		_spawn_entity(path, Vector2.ZERO)
		
		# 3. Pequeno delay para não travar o jogo
		await get_tree().create_timer(0.2).timeout

# --- LÓGICA DE SPAWN E POSICIONAMENTO ---

func _spawn_entity(resource_path: String, positionLoc: Vector2):
	# 1. Define a posição inicial
	if positionLoc != Vector2.ZERO:
		spawn_position = positionLoc
	else:
		if not is_instance_valid(player):
			return 
			
		# Gera posição circular ao redor do player
		var angulo_aleatorio = randf() * TAU
		var distancia = randf_range(550.0, 850.0)
		var offset_vetor = Vector2(cos(angulo_aleatorio), sin(angulo_aleatorio)) * distancia
		spawn_position = player.global_position + offset_vetor

	# 2. Mantém dentro dos limites do mapa
	# (Só aplica se os limites foram calculados corretamente)
	if map_right > map_left + 100: 
		if not is_within_map_bounds(spawn_position):
			spawn_position = clamp_position_to_bounds(spawn_position)
	
	# 3. Validação de Navegação (Evita paredes)
	if nav_region: 
		var mapa_rid = nav_region.get_navigation_map()
		spawn_position = NavigationServer2D.map_get_closest_point(mapa_rid, spawn_position)
	
	# 4. Instancia o inimigo
	var resource = load(resource_path)
	if resource:
		var entity = resource.instantiate()
		entity.global_position = spawn_position # Use global_position para garantir
		call_deferred("add_child", entity)

# --- FUNÇÕES AUXILIARES DE LIMITES ---

func is_within_map_bounds(pos: Vector2) -> bool:
	return pos.x >= map_left and pos.x <= map_right and pos.y >= map_top and pos.y <= map_bottom

func clamp_position_to_bounds(pos: Vector2) -> Vector2:
	# Margem de segurança (padding) de 100px para não spawnar exatamente na borda
	var padding = 100.0
	pos.x = clamp(pos.x, map_left + padding, map_right - padding)
	pos.y = clamp(pos.y, map_top + padding, map_bottom - padding)
	return pos
