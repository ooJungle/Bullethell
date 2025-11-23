extends Node2D

@onready var portal_volta = $portal_volta
@onready var colisao_portal = $portal_volta/CollisionShape2D

var total_cristais = 0
var cristais_quebrados = 0

@export var nav_region: NavigationRegion2D
@export var tilemap: TileMapLayer

# Variáveis para armazenar os limites
var map_left: float
var map_right: float
var map_top: float
var map_bottom: float

# Intervalo de spawn de inimigos
var spawn_interval: float = 3.5
var spawn_offset: float = 50.0
var enemy_timer: Timer

# Inimigos comuns têm peso 10, Inimigos raros (laser, caixinha e maguinhas) têm peso 2.5
var enemies_list = [
	{"path": "res://Cenas/Inimigos/inimigo_0.tscn", "weight": 10},
	{"path": "res://Cenas/Inimigos/inimigo_1.tscn", "weight": 10},
	{"path": "res://Cenas/Inimigos/inimigo_2.tscn", "weight": 2.5},
	{"path": "res://Cenas/Inimigos/inimigo_4.tscn", "weight": 2.5},
	{"path": "res://Cenas/Inimigos/Inimigo_5.tscn", "weight": 2.5},
	{"path": "res://Cenas/Inimigos/inimigo_6.tscn", "weight": 10},
	{"path": "res://Cenas/Inimigos/inimigo_laser.tscn", "weight": 2.5},
	{"path": "res://Cenas/Inimigos/inimigo_polvo.tscn", "weight": 10},
	{"path": "res://Cenas/Inimigos/inimigo_qualquer.tscn", "weight": 10}
]

var player
var spawn_position

var pause_control_path = "/root/fase_teste/PauseMenu"
var pause_control

func _ready():
	player = get_tree().get_first_node_in_group("players")

	# Obtenha as posições globais dos limites
	if nav_region is NavigationRegion2D:
		# Tente encontrar o TileMap que é filho da NavigationRegion
		if tilemap is TileMapLayer:
			# Pega o retângulo de células usadas (ex: de (0,0) até (50, 30))
			var used_rect: Rect2i = tilemap.get_used_rect()
			
			# Converte os cantos desse retângulo para posições de pixel GLOBAIS
			var top_left_global: Vector2 = tilemap.to_global(tilemap.map_to_local(used_rect.position))
			
			# Precisamos do canto inferior direito
			var bottom_right_pos = used_rect.position + used_rect.size
			var bottom_right_global: Vector2 = tilemap.to_global(tilemap.map_to_local(bottom_right_pos))
			
			# Define as variáveis de limite
			map_left = top_left_global.x
			map_top = top_left_global.y
			map_right = bottom_right_global.x
			map_bottom = bottom_right_global.y
			
			print("Limites do mapa definidos: ", map_left, map_top, map_right, map_bottom)
		else:
			printerr("Erro no BattleManager: Não foi possível encontrar o nó 'TileMapLayer' como filho da 'nav_region'.")
	else:
		printerr("Erro no BattleManager: A variável 'nav_region' não foi atribuída no Inspetor.")

	# Cria e configura o Timer para inimigos
	enemy_timer = Timer.new()
	enemy_timer.name = "EnemyTimer"
	enemy_timer.wait_time = spawn_interval
	enemy_timer.one_shot = false
	enemy_timer.autostart = true
	enemy_timer.connect("timeout", Callable(self, "spawn_enemy"))
	add_child(enemy_timer)

	portal_volta.visible = false
	colisao_portal.set_deferred("disabled", true)
	
	var lista_cristais = get_tree().get_nodes_in_group("cristais")
	total_cristais = lista_cristais.size()
	
	print("Fase iniciada. Total de cristais: ", total_cristais)
	
	for cristal in lista_cristais:
		cristal.fui_quebrado.connect(_on_cristal_quebrado)

func _on_cristal_quebrado():
	cristais_quebrados += 1
	print("Cristal quebrado! ", cristais_quebrados, "/", total_cristais)
	
	if cristais_quebrados >= total_cristais:
		abrir_portal()

	spawn_enemy()
	
func abrir_portal():
	portal_volta.visible = true
	colisao_portal.set_deferred("disabled", false)
		
	if player:
		player.ativar_seta_guia(portal_volta.global_position)

func is_within_map_bounds(positionMap: Vector2) -> bool:
	return positionMap.x >= map_left and positionMap.x <= map_right and positionMap.y >= map_top and positionMap.y <= map_bottom

func clamp_position_to_bounds(positionMap: Vector2) -> Vector2:
	# Ajusta a posição para ficar dentro dos limites do mapa
	positionMap.x = clamp(positionMap.x, map_left+275, map_right-275)
	positionMap.y = clamp(positionMap.y, map_top+225, map_bottom-225)
	return positionMap

func spawn_enemy():
	var quantity = randi() % 3
	if quantity>1:
		quantity=2
	else:
		quantity=1
	for i in range(quantity):
		# 1. Calcular peso total
		var total_weight: int = 0
		for enemy_data in enemies_list:
			total_weight += enemy_data["weight"]
		
		# 2. Sorteio
		var random_val = randi() % total_weight
		var current_sum = 0
		var selected_path = ""
		
		# 3. Selecionar o inimigo baseado no peso
		for enemy_data in enemies_list:
			current_sum += enemy_data["weight"]
			if random_val < current_sum:
				selected_path = enemy_data["path"]
				break
		
		# 4. Spawnar
		if selected_path != "":
			_spawn_entity(selected_path, Vector2.ZERO)

func _spawn_entity(resource_path: String, positionLoc):
	var camera = get_tree().get_current_scene().get_node("player/Camera2D")
	if not camera: 
		return

	var camera_pos = camera.global_position
	var viewport_size = get_viewport().get_visible_rect().size / 2
	
	# Calcule as bordas da câmera
	var left = camera_pos.x - viewport_size.x - spawn_offset
	var right = camera_pos.x + viewport_size.x + spawn_offset
	var top = camera_pos.y - viewport_size.y - spawn_offset
	var bottom = camera_pos.y + viewport_size.y + spawn_offset

	if positionLoc == Vector2.ZERO:
		spawn_position = Vector2()
		var side = randi() % 4 # 0 = top, 1 = bottom, 2 = left, 3 = right
		match side:
			0: # Top
				spawn_position.x = randf_range(left, right)
				spawn_position.y = top
			1: # Bottom
				spawn_position.x = randf_range(left, right)
				spawn_position.y = bottom
			2: # Left
				spawn_position.x = left
				spawn_position.y = randf_range(top, bottom)
			3: # Right
				spawn_position.x = right
				spawn_position.y = randf_range(top, bottom)
	else:
		spawn_position = positionLoc

	if not is_within_map_bounds(spawn_position):
		spawn_position = clamp_position_to_bounds(spawn_position)

	var resource = load(resource_path)
	if resource:
		var entity = resource.instantiate()
		entity.position = spawn_position
		add_child(entity)
