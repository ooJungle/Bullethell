extends CharacterBody2D

enum States {IDLE, MOVE, DRAG_SELECT, CTRL_CV, BUCKET_FILL}
var current_state = States.IDLE

@export var player: Node2D
@onready var selection_box = $SelectionBox
@onready var selection_area = $SelectionBox/Area2D
@onready var sprite = $Sprite2D

var target_position: Vector2
var camera_rect: Rect2
var player_camera: Camera2D
var navigation_region: NavigationRegion2D
var arena_rect: Rect2

func _ready():
	player = get_node_or_null("/root/Node2D/player")
	if not player:
		player = get_node_or_null("/root/fase_teste/player")

	player_camera = player.get_node("Camera2D") 
	player_camera.zoom = Vector2(1, 1)
	
	# Encontra a região de navegação (arena)
	navigation_region = get_node_or_null("/root/Node2D/NavigationRegion2D")
	if navigation_region:
		arena_rect = _get_navigation_bounds()
	else:
		# Fallback: usa a área da câmera
		arena_rect = camera_rect
		print("AVISO: NavigationRegion2D não encontrado, usando área da câmera como fallback")
	
	# VERIFICAÇÃO DA SPRITE
	if not sprite or not sprite.texture:
		print("AVISO: Sprite do boss não encontrada ou sem textura!")
		sprite = $Sprite2D
		if sprite and not sprite.texture:
			print("Sprite ainda sem textura - verifique no inspector")
			
	# Calcula a área visível da câmera
	_update_camera_rect()
	
	selection_box.visible = false
	_start_next_attack()

func _get_navigation_bounds() -> Rect2:
	# Obtém os limites da região de navegação
	# Nota: Isso pode variar dependendo de como sua NavigationRegion2D está configurada
	# Esta é uma implementação genérica - você pode precisar ajustar
	var nav_vertices = navigation_region.navigation_polygon.get_vertices()
	if nav_vertices.size() == 0:
		return camera_rect
	
	var min_x = nav_vertices[0].x
	var max_x = nav_vertices[0].x
	var min_y = nav_vertices[0].y
	var max_y = nav_vertices[0].y
	
	for vertex in nav_vertices:
		min_x = min(min_x, vertex.x)
		max_x = max(max_x, vertex.x)
		min_y = min(min_y, vertex.y)
		max_y = max(max_y, vertex.y)
	
	return Rect2(min_x, min_y, max_x - min_x, max_y - min_y)

func _update_camera_rect():
	# Calcula a área visível da câmera baseada na posição e zoom
	if player_camera:
		var viewport_size = get_viewport_rect().size
		var zoom = player_camera.zoom
		var camera_center = player_camera.global_position
		
		# Calcula os limites da câmera
		var camera_width = viewport_size.x / zoom.x
		var camera_height = viewport_size.y / zoom.y
		
		camera_rect = Rect2(
			camera_center - Vector2(camera_width / 2, camera_height / 2),
			Vector2(camera_width, camera_height)
		)

func _process(delta):
	# Atualiza a área da câmera periodicamente
	if Engine.get_frames_drawn() % 12 == 0:
		_update_camera_rect()
	
	# Movimento suave do mouse (Lerp)
	if current_state == States.MOVE or current_state == States.IDLE:
		global_position = global_position.lerp(target_position, 3 * delta)

func _start_next_attack():
	# Escolhe um ataque aleatório
	var attacks = [States.DRAG_SELECT, States.CTRL_CV, States.BUCKET_FILL]
	var next_attack = attacks.pick_random()
	
	# Pequena pausa antes de atacar (Telegraph)
	current_state = States.IDLE
	
	# Vai para uma posição aleatória ao redor do player, mas dentro da área da câmera E da arena
	target_position = _get_position_around_player()
	await get_tree().create_timer(1.0).timeout
	
	match next_attack:
		States.DRAG_SELECT:
			attack_drag_select()
		States.CTRL_CV:
			attack_ctrl_cv()
		States.BUCKET_FILL:
			attack_bucket_fill()

func _get_position_around_player() -> Vector2:
	# Retorna uma posição aleatória ao redor do player, mas dentro da arena
	if not player:
		return global_position
	
	var margin = 100
	var attempts = 0
	var max_attempts = 10
	
	while attempts < max_attempts:
		# Gera uma posição em um círculo ao redor do player
		var angle = randf() * 2 * PI
		var distance = randf_range(150, 300)
		var candidate_pos = player.global_position + Vector2(cos(angle), sin(angle)) * distance
		
		# Verifica se está dentro da arena (com margem)
		if (_is_point_in_arena(candidate_pos) and
			candidate_pos.x > arena_rect.position.x + margin and
			candidate_pos.x < arena_rect.end.x - margin and
			candidate_pos.y > arena_rect.position.y + margin and
			candidate_pos.y < arena_rect.end.y - margin):
			return candidate_pos
		
		attempts += 1
	
	# Fallback: centro da arena
	return arena_rect.get_center()

func _is_point_in_arena(point: Vector2) -> bool:
	# Verifica se um ponto está dentro da arena
	# Esta é uma verificação simples de retângulo - você pode precisar de verificação mais complexa
	# se sua arena não for retangular
	return arena_rect.has_point(point)

# ---------------------------------------------------------
# ATAQUE 1: DRAG & SELECT (Caixa de Seleção)
# ---------------------------------------------------------
# ---------------------------------------------------------
# ATAQUE 1: DRAG & SELECT (Caixa de Seleção) - CORRIGIDO
# ---------------------------------------------------------
func attack_drag_select():
	current_state = States.DRAG_SELECT
	
	# 1. Mouse vai para uma posição inicial aleatória dentro da câmera
	var margin = 50
	var start_pos = Vector2(
		randf_range(camera_rect.position.x + margin, camera_rect.end.x - margin),
		randf_range(camera_rect.position.y + margin, camera_rect.end.y - margin)
	)
	target_position = start_pos
	
	# Espera o mouse chegar lá
	await get_tree().create_timer(0.5).timeout
	
	# 2. Prepara a caixa visual - começa da posição atual do mouse
	selection_box.visible = true
	selection_box.size = Vector2(0, 0)
	selection_box.global_position = global_position  # Começa da posição atual do boss
	
	# 3. Determina direção e tamanho da expansão (em direção ao player ou aleatória)
	var expand_direction: Vector2
	if randf() < 0.7:  # 70% de chance de expandir em direção ao player
		expand_direction = (player.global_position - global_position).normalized()
	else:  # 30% de chance de direção aleatória
		expand_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	
	# Calcula o tamanho máximo possível dentro da câmera
	var max_distance_x = 0.0
	var max_distance_y = 0.0
	
	if expand_direction.x > 0:  # Expandindo para a direita
		max_distance_x = camera_rect.end.x - global_position.x - 10
	else:  # Expandindo para a esquerda
		max_distance_x = global_position.x - camera_rect.position.x - 10
		
	if expand_direction.y > 0:  # Expandindo para baixo
		max_distance_y = camera_rect.end.y - global_position.y - 10
	else:  # Expandindo para cima
		max_distance_y = global_position.y - camera_rect.position.y - 10
	
	# Calcula o tamanho final baseado na direção e limites da câmera
	var target_width = randf_range(200, 400)
	var target_height = randf_range(200, 400)
	
	# Ajusta o tamanho para não ultrapassar os limites
	if expand_direction.x != 0:
		var max_width = abs(max_distance_x / expand_direction.x) if expand_direction.x != 0 else target_width
		target_width = min(target_width, max_width)
	
	if expand_direction.y != 0:
		var max_height = abs(max_distance_y / expand_direction.y) if expand_direction.y != 0 else target_height
		target_height = min(target_height, max_height)
	
	# Garante tamanho mínimo
	target_width = max(target_width, 100)
	target_height = max(target_height, 100)
	
	var target_box_size = Vector2(target_width, target_height)
	
	# 4. Animação de expansão da caixa
	var tween = create_tween()
	tween.tween_property(selection_box, "size", target_box_size, 1.0)
	
	# Move o mouse junto com a expansão (opcional - pode comentar se não quiser)
	var target_pos = global_position + expand_direction * Vector2(target_width, target_height)
	tween.parallel().tween_property(self, "global_position", target_pos, 1.0)
	
	await tween.finished
	
	# 5. Dano! (Chuva de balas na área)
	# Cria um retângulo global baseado na posição e tamanho da caixa de seleção
	var box_global_rect = Rect2(
		selection_box.global_position,
		selection_box.size
	)
	
	# Garante que o retângulo está dentro da câmera
	var clamped_rect = _clamp_rect_to_camera(box_global_rect)
	_spawn_bullets_in_area(clamped_rect)
	
	await get_tree().create_timer(0.5).timeout
	selection_box.visible = false
	_start_next_attack()

# ---------------------------------------------------------
# ATAQUE 2: CTRL+C / CTRL+V (Clones)
# ---------------------------------------------------------
func attack_ctrl_cv():
	current_state = States.CTRL_CV
	
	# Mouse vai até o jogador
	target_position = player.global_position
	await get_tree().create_timer(1.0).timeout
	
	# Efeito visual "Copiar"
	print("Ctrl+C") 
	
	# Mouse se afasta para uma borda de um quadrante aleatório
	var random_quadrant = _get_random_quadrant()
	var quadrant_rect = _get_quadrant_rect(random_quadrant)
	
	var edge_positions = [
		Vector2(quadrant_rect.position.x, quadrant_rect.position.y),        # Canto superior esquerdo do quadrante
		Vector2(quadrant_rect.end.x, quadrant_rect.position.y),            # Canto superior direito do quadrante
		Vector2(quadrant_rect.position.x, quadrant_rect.end.y),            # Canto inferior esquerdo do quadrante
		Vector2(quadrant_rect.end.x, quadrant_rect.end.y)                  # Canto inferior direito do quadrante
	]
	target_position = edge_positions[randi() % edge_positions.size()]
	await get_tree().create_timer(0.5).timeout
	
	# Cola as cópias em quadrantes diferentes
	var used_quadrants = [random_quadrant]
	for i in range(3):
		print("Ctrl+V")
		# Escolhe um quadrante diferente para cada clone
		var clone_quadrant = _get_different_quadrant(used_quadrants)
		used_quadrants.append(clone_quadrant)
		
		var clone_pos = _get_random_position_in_quadrant(clone_quadrant, 50)
		target_position = clone_pos
		await get_tree().create_timer(0.3).timeout
		
		var clone = load("res://Cenas/Inimigos/ClonePlayer.tscn").instantiate()
		clone.global_position = clone_pos
		get_parent().add_child(clone)
	
	_start_next_attack()

# ---------------------------------------------------------
# ATAQUE 3: BUCKET FILL (O chão é lava)
# ---------------------------------------------------------
func attack_bucket_fill():
	current_state = States.BUCKET_FILL
	
	# Mouse vai para o centro da câmera
	target_position = camera_rect.get_center()
	await get_tree().create_timer(1.0).timeout
	
	# 1. Cria Zonas Seguras (Ilhas) em quadrantes opostos
	var zone_scene = load("res://Cenas/Fases/Zone.tscn")
	var safe_zones = []
	
	# Pares de quadrantes opostos
	var opposite_pairs = [
		[0, 3],  # Superior esquerdo e inferior direito
		[1, 2]   # Superior direito e inferior esquerdo
	]
	
	# Escolhe um par de quadrantes opostos aleatoriamente
	var selected_pair = opposite_pairs[randi() % opposite_pairs.size()]
	
	for quadrant_index in selected_pair:
		var zone_pos = _get_random_position_in_quadrant(quadrant_index, 50)
		
		var zone = zone_scene.instantiate()
		zone.modulate = Color(0, 1, 0, 0.5)
		zone.global_position = zone_pos
		get_parent().add_child(zone)
		safe_zones.append(zone)
	
	# 2. Cria efeito visual de alerta vermelho
	var danger_overlay = ColorRect.new()
	danger_overlay.color = Color(1, 0, 0, 0.1)
	danger_overlay.size = get_viewport_rect().size
	danger_overlay.position = Vector2.ZERO
	danger_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 10
	canvas_layer.add_child(danger_overlay)
	get_tree().root.add_child(canvas_layer)
	
	# 3. Anima o aumento gradual do vermelho
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(danger_overlay, "color:a", 0.6, 2.0)
	
	# Aviso visual
	print("Atenção! Preenchendo...")
	await get_tree().create_timer(2.0).timeout
	
	# 4. Verifica se o jogador está nas zonas seguras
	var is_safe = false
	for zone in safe_zones:
		if player.global_position.distance_to(zone.global_position) < 100:
			is_safe = true
	
	# 5. Aplica dano se não estiver salvo
	if not is_safe:
		print("DANO DO BALDE!")
		if player.has_method("take_damage"):
			player.take_damage(25)
	
	# 6. Remove o efeito vermelho com fade out
	var fade_tween = create_tween()
	fade_tween.tween_property(danger_overlay, "color:a", 0.0, 0.5)
	await fade_tween.finished
	
	# Limpa zonas e efeitos visuais
	for zone in safe_zones:
		zone.queue_free()
	canvas_layer.queue_free()
		
	_start_next_attack()

# =========================================================
# FUNÇÕES AUXILIARES PARA QUADRANTES DA CÂMERA
# =========================================================
func _clamp_rect_to_camera(rect: Rect2) -> Rect2:
	# Garante que um retângulo esteja completamente dentro da área da câmera
	var clamped_position = Vector2(
		max(rect.position.x, camera_rect.position.x),
		max(rect.position.y, camera_rect.position.y)
	)
	
	var clamped_end = Vector2(
		min(rect.end.x, camera_rect.end.x),
		min(rect.end.y, camera_rect.end.y)
	)
	
	return Rect2(clamped_position, clamped_end - clamped_position)
	
func _get_quadrant_rect(quadrant_index: int) -> Rect2:
	# Divide a área da câmera em 4 quadrantes
	var quadrant_size = camera_rect.size / 2
	match quadrant_index:
		0:  # Superior esquerdo
			return Rect2(camera_rect.position, quadrant_size)
		1:  # Superior direito
			return Rect2(
				Vector2(camera_rect.position.x + quadrant_size.x, camera_rect.position.y),
				quadrant_size
			)
		2:  # Inferior esquerdo
			return Rect2(
				Vector2(camera_rect.position.x, camera_rect.position.y + quadrant_size.y),
				quadrant_size
			)
		3:  # Inferior direito
			return Rect2(
				camera_rect.position + quadrant_size,
				quadrant_size
			)
		_:
			return camera_rect

func _get_random_quadrant() -> int:
	# Retorna um índice de quadrante aleatório (0-3)
	return randi() % 4

func _get_different_quadrant(used_quadrants: Array) -> int:
	# Retorna um quadrante diferente dos já usados
	var available_quadrants = [0, 1, 2, 3]
	for used in used_quadrants:
		available_quadrants.erase(used)
	
	if available_quadrants.size() > 0:
		return available_quadrants[randi() % available_quadrants.size()]
	else:
		return _get_random_quadrant()

func _get_random_position_in_quadrant(quadrant_index: int, margin: float = 0) -> Vector2:
	# Retorna uma posição aleatória dentro de um quadrante específico
	var quadrant_rect = _get_quadrant_rect(quadrant_index)
	return Vector2(
		randf_range(quadrant_rect.position.x + margin, quadrant_rect.end.x - margin),
		randf_range(quadrant_rect.position.y + margin, quadrant_rect.end.y - margin)
	)

func _clamp_rect_to_quadrant(rect: Rect2, quadrant_index: int) -> Rect2:
	# Garante que um retângulo esteja completamente dentro de um quadrante
	var quadrant_rect = _get_quadrant_rect(quadrant_index)
	
	var clamped_position = Vector2(
		max(rect.position.x, quadrant_rect.position.x),
		max(rect.position.y, quadrant_rect.position.y)
	)
	
	var clamped_end = Vector2(
		min(rect.end.x, quadrant_rect.end.x),
		min(rect.end.y, quadrant_rect.end.y)
	)
	
	return Rect2(clamped_position, clamped_end - clamped_position)

func _spawn_bullets_in_area(rect: Rect2):
	var blaster_scene = load("res://Cenas/Projeteis/Blaster.tscn")
	var count = 20
	var delay = 0.05

	for i in range(count):
		var laser = blaster_scene.instantiate()
		get_parent().add_child(laser)
		
		var spawn_pos: Vector2
		var orientation = randi() % 2
		
		if orientation == 0: 
			var x_pos = randf_range(rect.position.x, rect.end.x)
			var y_pos
			
			if randf() < 0.5:
				y_pos = rect.position.y
				laser.rotation_degrees = 90
			else:
				y_pos = rect.end.y
				laser.rotation_degrees = 270
			
			spawn_pos = Vector2(x_pos, y_pos)
			
		else:
			var x_pos
			var y_pos = randf_range(rect.position.y, rect.end.y)
			
			if randf() < 0.5:
				x_pos = rect.position.x
				laser.rotation_degrees = 0
			else:
				x_pos = rect.end.x
				laser.rotation_degrees = 180
				
			spawn_pos = Vector2(x_pos, y_pos)

		laser.global_position = spawn_pos
		await get_tree().create_timer(delay).timeout
