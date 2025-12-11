extends Node2D

@onready var portal_volta = $portal_volta
@onready var colisao_portal = $portal_volta/CollisionShape2D
@onready var musica_inicio: AudioStreamPlayer = $AudioStreamPlayer2D
@onready var camera_shake: AnimationPlayer = $player/Camera2D/AnimationPlayer
@onready var tut: CanvasLayer = $tut
@onready var troca: AudioStreamPlayer = $troca

var total_cristais = 0
var cristais_quebrados = 0

@export var nav_region: NavigationRegion2D
@export var tilemap: TileMapLayer

# Variáveis para armazenar os limites
var map_left: float
var map_right: float
var map_top: float
var map_bottom: float

# --- CONTROLE DE SPAWN ---
var spawn_interval: float = 3.5
var spawn_offset: float = 50.0
var enemy_timer: Timer

# --- NOVAS VARIÁVEIS (CONTROLE DE ONDA/PAUSA) ---
var inimigos_spawnados_contagem: int = 0
var limite_inimigos_onda: int = 5
var tempo_descanso: float = 20.0
var rest_timer: Timer
# ------------------------------------------------

# Inimigos comuns têm peso 10, Inimigos raros (laser, caixinha e maguinhas) têm peso 2.5
var enemies_list = [
	{"path": "res://Cenas/Inimigos/inimigo_zumbi.tscn", "weight": 100},
	{"path": "res://Cenas/Inimigos/inimigo_bola.tscn", "weight": 100}
	]

var player
var spawn_position

var pause_control_path = "/root/fase_teste/PauseMenu"
var pause_control

func _ready():
	tut.visible = false
	player = get_tree().get_first_node_in_group("players")

	# Obtenha as posições globais dos limites
	if nav_region is NavigationRegion2D:
		if tilemap is TileMapLayer:
			var used_rect: Rect2i = tilemap.get_used_rect()
			var top_left_global: Vector2 = tilemap.to_global(tilemap.map_to_local(used_rect.position))
			var bottom_right_pos = used_rect.position + used_rect.size
			var bottom_right_global: Vector2 = tilemap.to_global(tilemap.map_to_local(bottom_right_pos))
			
			map_left = top_left_global.x
			map_top = top_left_global.y
			map_right = bottom_right_global.x
			map_bottom = bottom_right_global.y
			
			print("Limites do mapa definidos: ", map_left, map_top, map_right, map_bottom)
		else:
			printerr("Erro no BattleManager: Não foi possível encontrar o nó 'TileMapLayer' como filho da 'nav_region'.")
	else:
		printerr("Erro no BattleManager: A variável 'nav_region' não foi atribuída no Inspetor.")

	# --- CONFIGURAÇÃO DO TIMER DE INIMIGOS ---
	enemy_timer = Timer.new()
	enemy_timer.name = "EnemyTimer"
	enemy_timer.wait_time = spawn_interval
	enemy_timer.one_shot = false
	enemy_timer.autostart = true
	enemy_timer.connect("timeout", Callable(self, "spawn_enemy"))
	add_child(enemy_timer)

	# --- CONFIGURAÇÃO DO TIMER DE DESCANSO (NOVO) ---
	rest_timer = Timer.new()
	rest_timer.name = "RestTimer"
	rest_timer.wait_time = tempo_descanso
	rest_timer.one_shot = true # Só roda uma vez por pausa
	rest_timer.timeout.connect(_on_rest_finished)
	add_child(rest_timer)
	# ------------------------------------------------

	get_tree().get_root().set_transparent_background(true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true, 0)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true, 0)
	portal_volta.visible = false
	colisao_portal.set_deferred("disabled", true)
	
	var lista_cristais = get_tree().get_nodes_in_group("cristais")
	total_cristais = lista_cristais.size()
	
	print("Fase iniciada. Total de cristais: ", total_cristais)
	
	for cristal in lista_cristais:
		cristal.fui_quebrado.connect(_on_cristal_quebrado)
	
	spawn_enemy()
	
	controlar_audio()

func controlar_audio():
	var global_player = Global.music_player
	if global_player:
		var volume_original = global_player.volume_db
		var tween_down = create_tween()
		tween_down.tween_property(global_player, "volume_db", -25.0, 4.0)
		
		await tween_down.finished
		global_player.stream_paused = true
		
		if musica_inicio:
			musica_inicio.play()
			await musica_inicio.finished
		
		global_player.stream_paused = false
		
		var tween_up = create_tween()
		tween_up.tween_property(global_player, "volume_db", volume_original, 4.0)
	
func _on_cristal_quebrado():
	cristais_quebrados += 1
	print("Cristal quebrado! ", cristais_quebrados, "/", total_cristais)
	if cristais_quebrados >= 3:
		camera_shake.play("camera_shake")
	
	if cristais_quebrados >= total_cristais:
		tut.visible = true
		troca.play()
		Global.plataforma = true
		abrir_portal()

func abrir_portal():
	portal_volta.visible = true
	colisao_portal.set_deferred("disabled", false)
		
	if player:
		player.ativar_seta_guia(portal_volta.global_position)

func is_within_map_bounds(positionMap: Vector2) -> bool:
	return positionMap.x >= map_left and positionMap.x <= map_right and positionMap.y >= map_top and positionMap.y <= map_bottom

func clamp_position_to_bounds(positionMap: Vector2) -> Vector2:
	positionMap.x = clamp(positionMap.x, map_left+275, map_right-275)
	positionMap.y = clamp(positionMap.y, map_top+225, map_bottom-225)
	return positionMap

func spawn_enemy():
	# Se por algum motivo o timer disparar durante o descanso, ignoramos
	if !rest_timer.is_stopped():
		return

	var quantity = randi() % 3
	if quantity > 1:
		quantity = 2
	else:
		quantity = 1
	
	for i in range(quantity):
		# --- VERIFICAÇÃO DE LIMITE DE ONDA ---
		if inimigos_spawnados_contagem >= limite_inimigos_onda:
			iniciar_descanso()
			break # Para o loop 'for' imediatamente
		# -------------------------------------

		# 1. Calcular peso total
		var total_weight: int = 0
		for enemy_data in enemies_list:
			total_weight += enemy_data["weight"]
		
		# 2. Sorteio
		var random_val = randi() % total_weight
		var current_sum = 0
		var selected_path = ""
		
		for enemy_data in enemies_list:
			current_sum += enemy_data["weight"]
			if random_val < current_sum:
				selected_path = enemy_data["path"]
				break
		
		if selected_path != "":
			_spawn_entity(selected_path, Vector2.ZERO)
			inimigos_spawnados_contagem += 1
	
	if inimigos_spawnados_contagem >= limite_inimigos_onda and rest_timer.is_stopped():
		iniciar_descanso()

func iniciar_descanso():
	print("Limite de 10 inimigos atingido. Pausando spawn por 20 segundos...")
	enemy_timer.stop()
	rest_timer.start()

func _on_rest_finished():
	print("Descanso acabou! Reiniciando spawn.")
	inimigos_spawnados_contagem = 0
	enemy_timer.start()
	spawn_enemy()

func _spawn_entity(resource_path: String, positionLoc):
	# Se já veio com posição definida (ex: lógica específica), usa ela
	if positionLoc != Vector2.ZERO:
		spawn_position = positionLoc
	else:
		# --- LÓGICA DE SPAWN CIRCULAR AO REDOR DO PLAYER ---
		if not is_instance_valid(player):
			return # Se não tem player, não spawna
			
		# 1. Escolhe um ângulo aleatório (360 graus)
		var angulo_aleatorio = randf() * TAU
		
		# 2. Escolhe uma distância (longe o suficiente para ser fora da tela, mas não longe demais)
		# spawn_offset aqui funciona como raio mínimo
		var distancia = randf_range(550.0, 800.0) 
		
		# 3. Calcula a posição baseada no ângulo e distância
		var offset_vetor = Vector2(cos(angulo_aleatorio), sin(angulo_aleatorio)) * distancia
		spawn_position = player.global_position + offset_vetor

	# --- PROTEÇÃO DE LIMITES DO MAPA ---
	# Só aplica o clamp se os limites foram definidos corretamente (se o mapa tem tamanho real)
	if map_right > map_left + 100: 
		if not is_within_map_bounds(spawn_position):
			spawn_position = clamp_position_to_bounds(spawn_position)
	
	# --- VALIDAÇÃO DE CHÃO (NAVIGATION) ---
	# Impede que nasçam dentro de paredes ou buracos
	if nav_region: 
		var mapa_rid = nav_region.get_navigation_map()
		# Puxa para o chão válido mais próximo
		spawn_position = NavigationServer2D.map_get_closest_point(mapa_rid, spawn_position)
	
	# --- CRIAÇÃO DO INIMIGO ---
	var resource = load(resource_path)
	if resource:
		var entity = resource.instantiate()
		entity.position = spawn_position
		# call_deferred é essencial para evitar travamentos (lag) durante o jogo
		call_deferred("add_child", entity)
