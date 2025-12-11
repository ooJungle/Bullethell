extends CharacterBody2D

enum States {IDLE, MOVE, DRAG_SELECT, CTRL_CV, BUCKET_FILL}
var current_state = States.IDLE
signal vida_mudou(nova_vida)

@export var player: Node2D
@onready var selection_box = $SelectionBox
@onready var selection_area = $SelectionBox/Area2D
@onready var sprite = $Sprite2D

var target_position: Vector2
var camera_rect: Rect2
var player_camera: Camera2D
var navigation_region: NavigationRegion2D
var arena_rect: Rect2

var tween_dano: Tween

var vida = 550
var vida_max = 550

func _ready():
	player = get_node_or_null("/root/Node2D/player")
	if not player:
		player = get_node_or_null("/root/fase_teste/player")

	if player:
		player_camera = player.get_node("Camera2D") 
		player_camera.zoom = Vector2(1, 1)
	
	# Encontra a região de navegação (arena)
	navigation_region = get_node_or_null("/root/Node2D/NavigationRegion2D")
	if navigation_region:
		arena_rect = _get_navigation_bounds()
	else:
		# Fallback: usa a área da câmera se não tiver arena definida ainda
		if player_camera:
			_update_camera_rect()
			arena_rect = camera_rect
		else:
			arena_rect = Rect2(0, 0, 1000, 1000) # Fallback final
		print("AVISO: NavigationRegion2D não encontrado, usando fallback")
	
	# VERIFICAÇÃO DA SPRITE
	if not sprite or not sprite.texture:
		sprite = $Sprite2D
			
	# Calcula a área visível da câmera
	_update_camera_rect()
	
	if selection_box:
		selection_box.visible = false
	
	_start_next_attack()

func _get_navigation_bounds() -> Rect2:
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
	if player_camera:
		var viewport_size = get_viewport_rect().size
		var zoom = player_camera.zoom
		var camera_center = player_camera.global_position
		
		var camera_width = viewport_size.x / zoom.x
		var camera_height = viewport_size.y / zoom.y
		
		camera_rect = Rect2(
			camera_center - Vector2(camera_width / 2, camera_height / 2),
			Vector2(camera_width, camera_height)
		)

func _process(delta):
	if Engine.get_frames_drawn() % 12 == 0:
		_update_camera_rect()
	
	if current_state == States.MOVE or current_state == States.IDLE:
		global_position = global_position.lerp(target_position, 3 * delta)

func _start_next_attack():
	# Se morreu, não ataca mais
	if vida <= 0: return

	var attacks = [States.DRAG_SELECT, States.CTRL_CV, States.BUCKET_FILL]
	var next_attack = attacks.pick_random()
	
	current_state = States.IDLE
	target_position = _get_position_around_player()
	
	await get_tree().create_timer(1.0).timeout
	
	# Checagem dupla se morreu durante o timer
	if vida <= 0: return

	match next_attack:
		States.DRAG_SELECT:
			attack_drag_select()
		States.CTRL_CV:
			attack_ctrl_cv()
		States.BUCKET_FILL:
			attack_bucket_fill()

func _get_position_around_player() -> Vector2:
	if not player:
		return global_position
	
	var margin = 100
	var attempts = 0
	var max_attempts = 10
	
	while attempts < max_attempts:
		var angle = randf() * 2 * PI
		var distance = randf_range(150, 300)
		var candidate_pos = player.global_position + Vector2(cos(angle), sin(angle)) * distance
		
		if (_is_point_in_arena(candidate_pos) and
			candidate_pos.x > arena_rect.position.x + margin and
			candidate_pos.x < arena_rect.end.x - margin and
			candidate_pos.y > arena_rect.position.y + margin and
			candidate_pos.y < arena_rect.end.y - margin):
			return candidate_pos
		
		attempts += 1
	
	return arena_rect.get_center()

func _is_point_in_arena(point: Vector2) -> bool:
	return arena_rect.has_point(point)

# ---------------------------------------------------------
# ATAQUE 1: DRAG & SELECT
# ---------------------------------------------------------
func attack_drag_select():
	current_state = States.DRAG_SELECT
	
	var margin = 50
	var start_pos = Vector2(
		randf_range(camera_rect.position.x + margin, camera_rect.end.x - margin),
		randf_range(camera_rect.position.y + margin, camera_rect.end.y - margin)
	)
	target_position = start_pos
	
	await get_tree().create_timer(0.5).timeout
	
	selection_box.visible = true
	selection_box.size = Vector2(0, 0)
	selection_box.global_position = global_position 
	
	var expand_direction: Vector2
	if randf() < 0.7: 
		expand_direction = (player.global_position - global_position).normalized()
	else: 
		expand_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	
	var max_distance_x = 0.0
	var max_distance_y = 0.0
	
	if expand_direction.x > 0: 
		max_distance_x = camera_rect.end.x - global_position.x - 10
	else: 
		max_distance_x = global_position.x - camera_rect.position.x - 10
		
	if expand_direction.y > 0: 
		max_distance_y = camera_rect.end.y - global_position.y - 10
	else: 
		max_distance_y = global_position.y - camera_rect.position.y - 10
	
	var target_width = randf_range(200, 400)
	var target_height = randf_range(200, 400)
	
	if expand_direction.x != 0:
		var max_width = abs(max_distance_x / expand_direction.x) if expand_direction.x != 0 else target_width
		target_width = min(target_width, max_width)
	
	if expand_direction.y != 0:
		var max_height = abs(max_distance_y / expand_direction.y) if expand_direction.y != 0 else target_height
		target_height = min(target_height, max_height)
	
	target_width = max(target_width, 100)
	target_height = max(target_height, 100)
	
	var target_box_size = Vector2(target_width, target_height)
	
	var tween = create_tween()
	tween.tween_property(selection_box, "size", target_box_size, 1.0)
	
	var target_pos = global_position + expand_direction * Vector2(target_width, target_height)
	tween.parallel().tween_property(self, "global_position", target_pos, 1.0)
	
	await tween.finished
	
	var box_global_rect = Rect2(
		selection_box.global_position,
		selection_box.size
	)
	
	var clamped_rect = _clamp_rect_to_camera(box_global_rect)
	_spawn_bullets_in_area(clamped_rect)
	
	await get_tree().create_timer(0.5).timeout
	selection_box.visible = false
	_start_next_attack()

# ---------------------------------------------------------
# ATAQUE 2: CTRL+C / CTRL+V
# ---------------------------------------------------------
func attack_ctrl_cv():
	current_state = States.CTRL_CV
	
	target_position = player.global_position
	await get_tree().create_timer(1.0).timeout
	
	print("Ctrl+C") 
	
	var random_quadrant = _get_random_quadrant()
	var quadrant_rect = _get_quadrant_rect(random_quadrant)
	
	var edge_positions = [
		Vector2(quadrant_rect.position.x, quadrant_rect.position.y), 
		Vector2(quadrant_rect.end.x, quadrant_rect.position.y), 
		Vector2(quadrant_rect.position.x, quadrant_rect.end.y), 
		Vector2(quadrant_rect.end.x, quadrant_rect.end.y) 
	]
	target_position = edge_positions[randi() % edge_positions.size()]
	await get_tree().create_timer(0.5).timeout
	
	var used_quadrants = [random_quadrant]
	for i in range(3):
		print("Ctrl+V")
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
# ATAQUE 3: BUCKET FILL
# ---------------------------------------------------------
func attack_bucket_fill():
	current_state = States.BUCKET_FILL
	
	target_position = camera_rect.get_center()
	await get_tree().create_timer(1.0).timeout
	
	var zone_scene = load("res://Cenas/Fases/Zone.tscn")
	var safe_zones = []
	
	var opposite_pairs = [
		[0, 3], 
		[1, 2] 
	]
	
	var selected_pair = opposite_pairs[randi() % opposite_pairs.size()]
	
	for quadrant_index in selected_pair:
		var zone_pos = _get_random_position_in_quadrant(quadrant_index, 50)
		
		var zone = zone_scene.instantiate()
		zone.modulate = Color(0, 1, 0, 0.5)
		zone.global_position = zone_pos
		get_parent().add_child(zone)
		safe_zones.append(zone)
	
	var danger_overlay = ColorRect.new()
	danger_overlay.color = Color(1, 0, 0, 0.1)
	danger_overlay.size = get_viewport_rect().size
	danger_overlay.position = Vector2.ZERO
	danger_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 10
	canvas_layer.add_child(danger_overlay)
	get_tree().root.add_child(canvas_layer)
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(danger_overlay, "color:a", 0.6, 2.0)
	
	print("Atenção! Preenchendo...")
	await get_tree().create_timer(2.0).timeout
	
	var is_safe = false
	for zone in safe_zones:
		if player.global_position.distance_to(zone.global_position) < 100:
			is_safe = true
	
	if not is_safe:
		print("DANO DO BALDE!")
		if player.has_method("take_damage"):
			if canvas_layer:
				canvas_layer.queue_free()
			player.take_damage(1)
	
	var fade_tween = create_tween()
	fade_tween.tween_property(danger_overlay, "color:a", 0.0, 0.5)
	await fade_tween.finished
	
	for zone in safe_zones:
		zone.queue_free()
	if canvas_layer:
		canvas_layer.queue_free()
		
	_start_next_attack()

# =========================================================
# FUNÇÕES AUXILIARES
# =========================================================
func _clamp_rect_to_camera(rect: Rect2) -> Rect2:
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
	var quadrant_size = camera_rect.size / 2
	match quadrant_index:
		0: return Rect2(camera_rect.position, quadrant_size)
		1: return Rect2(Vector2(camera_rect.position.x + quadrant_size.x, camera_rect.position.y), quadrant_size)
		2: return Rect2(Vector2(camera_rect.position.x, camera_rect.position.y + quadrant_size.y), quadrant_size)
		3: return Rect2(camera_rect.position + quadrant_size, quadrant_size)
		_: return camera_rect

func _get_random_quadrant() -> int:
	return randi() % 4

func _get_different_quadrant(used_quadrants: Array) -> int:
	var available_quadrants = [0, 1, 2, 3]
	for used in used_quadrants:
		available_quadrants.erase(used)
	
	if available_quadrants.size() > 0:
		return available_quadrants[randi() % available_quadrants.size()]
	else:
		return _get_random_quadrant()

func _get_random_position_in_quadrant(quadrant_index: int, margin: float = 0) -> Vector2:
	var quadrant_rect = _get_quadrant_rect(quadrant_index)
	
	var valid_rect = quadrant_rect
	if arena_rect.has_area():
		valid_rect = quadrant_rect.intersection(arena_rect)
	
	if valid_rect.size.x <= 0 or valid_rect.size.y <= 0:
		return Vector2(
			clamp(quadrant_rect.position.x, arena_rect.position.x, arena_rect.end.x),
			clamp(quadrant_rect.position.y, arena_rect.position.y, arena_rect.end.y)
		)

	var min_x = valid_rect.position.x + margin
	var max_x = valid_rect.end.x - margin
	var min_y = valid_rect.position.y + margin
	var max_y = valid_rect.end.y - margin
	
	if min_x > max_x:
		var center_x = valid_rect.position.x + valid_rect.size.x / 2
		min_x = center_x
		max_x = center_x
		
	if min_y > max_y:
		var center_y = valid_rect.position.y + valid_rect.size.y / 2
		min_y = center_y
		max_y = center_y

	return Vector2(
		randf_range(min_x, max_x),
		randf_range(min_y, max_y)
	)
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

# =========================================================
# FUNÇÕES DE DANO E MORTE
# =========================================================

func take_damage(amount: int) -> void:
	# 1. Aplica o dano
	vida -= amount
	print("Boss tomou dano. Vida:", vida)
	emit_signal("vida_mudou", vida)
	# 2. Efeito Visual de Dano (Flash Vermelho)
	if tween_dano:
		tween_dano.kill()
	
	modulate = Color(1.0, 0.0, 0.0) # Flash Vermelho
	
	tween_dano = create_tween()
	tween_dano.tween_property(self, "modulate", Color.WHITE, 0.15).set_trans(Tween.TRANS_SINE)
	
	# 3. Verifica se morreu
	if vida <= 0:
		die()

func die() -> void:
	print("BOSS MORREU!")
	set_process(false)
	Global.boss_morreu()
