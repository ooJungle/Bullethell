extends Node2D
# Arraste as cenas dos seus inimigos (.tscn) para esta lista no Inspector
@export var lista_inimigos: Array[PackedScene]
@export var intervalo_spawn: float = 2.0
@export var navigation_region: NavigationRegion2D
@onready var timer: Timer = $Timer
@onready var area_spawn: ReferenceRect = $AreaDeSpawn

func _ready() -> void:
	timer.wait_time = intervalo_spawn
	timer.timeout.connect(_on_timer_timeout)
	timer.start()
	
	area_spawn.visible = false

func _on_timer_timeout() -> void:
	spawnar_inimigo()

func spawnar_inimigo():
	if lista_inimigos.is_empty() or not navigation_region:
		print("ERRO: Configure a lista de inimigos e o NavigationRegion no Spawner!")
		return

	var cena_inimigo = lista_inimigos.pick_random()
	var inimigo = cena_inimigo.instantiate()
	
	var posicao_valida = obter_posicao_no_navmesh()
	inimigo.global_position = posicao_valida
	get_parent().add_child(inimigo)

func obter_posicao_no_navmesh() -> Vector2:
	var rect_pos = area_spawn.global_position
	var rect_size = area_spawn.size
	
	var random_x = randf_range(rect_pos.x, rect_pos.x + rect_size.x)
	var random_y = randf_range(rect_pos.y, rect_pos.y + rect_size.y)
	var ponto_aleatorio = Vector2(random_x, random_y)
	
	var mapa_rid = navigation_region.get_navigation_map()
	var ponto_no_chao = NavigationServer2D.map_get_closest_point(mapa_rid, ponto_aleatorio)
	
	return ponto_no_chao
