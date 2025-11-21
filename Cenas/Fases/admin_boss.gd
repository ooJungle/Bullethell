extends CharacterBody2D

enum States {IDLE, MOVE, DRAG_SELECT, CTRL_CV, BUCKET_FILL}
var current_state = States.IDLE

@export var player: Node2D
@onready var selection_box = $SelectionBox
@onready var selection_area = $SelectionBox/Area2D
@onready var sprite = $Sprite2D

var target_position: Vector2
var screen_size: Vector2

func _ready():
	player = get_node_or_null("/root/Node2D/player")
	if not player:
		player = get_node_or_null("/root/fase_teste/player")

	var camera = player.get_node("Camera2D") 
	camera.zoom = Vector2(0.75, 0.75)
	var label = camera.get_node("Label")
	label.position.x = 696.0
	label.position.y = -423.0
	
	player.get_children()[0].zoom = 0.75
	player.get_children()[0].position.x = 696.0
	player.get_children()[0].position.y = -423
	
	screen_size = get_viewport_rect().size
	selection_box.visible = false
	_start_next_attack()

func _process(delta):
	# Movimento suave do mouse (Lerp)
	if current_state == States.MOVE or current_state == States.IDLE:
		global_position = global_position.lerp(target_position, 5 * delta)

func _start_next_attack():
	# Escolhe um ataque aleatório
	var attacks = [States.DRAG_SELECT, States.CTRL_CV, States.BUCKET_FILL]
	var next_attack = attacks.pick_random()
	
	# Pequena pausa antes de atacar (Telegraph)
	current_state = States.IDLE
	target_position = Vector2(screen_size.x / 2, screen_size.y / 2) # Vai para o meio ou persegue
	await get_tree().create_timer(1.5).timeout
	
	match next_attack:
		States.DRAG_SELECT:
			attack_drag_select()
		States.CTRL_CV:
			attack_ctrl_cv()
		States.BUCKET_FILL:
			attack_bucket_fill()

# ---------------------------------------------------------
# ATAQUE 1: DRAG & SELECT (Caixa de Seleção)
# ---------------------------------------------------------
func attack_drag_select():
	current_state = States.DRAG_SELECT
	
	# 1. Mouse vai para uma posição inicial aleatória
	var start_pos = Vector2(randf_range(100, screen_size.x - 100), randf_range(100, screen_size.y - 100))
	target_position = start_pos
	
	# Espera o mouse chegar lá
	await get_tree().create_timer(0.5).timeout
	
	# 2. Prepara a caixa visual
	selection_box.visible = true
	selection_box.size = Vector2(0, 0)
	selection_box.global_position = start_pos
	
	# 3. Expande a caixa em direção ao jogador ou aleatoriamente
	var target_box_size = Vector2(randf_range(200, 400), randf_range(200, 400))
	
	var tween = create_tween()
	tween.tween_property(selection_box, "size", target_box_size, 1.0)
	# Move o mouse junto com a ponta da caixa
	tween.parallel().tween_property(self, "global_position", start_pos + target_box_size, 1.0)
	
	await tween.finished
	
	# 4. Dano! (Chuva de balas ou Dano Instantâneo na área)
	_spawn_bullets_in_area(selection_box.get_global_rect())
	
	await get_tree().create_timer(0.5).timeout
	selection_box.visible = false
	_start_next_attack()

func _spawn_bullets_in_area(rect: Rect2):
	var blaster_scene = load("res://Cenas/Projeteis/Blaster.tscn")
	var count = 20
	var delay = 0.05 # Velocidade entre os disparos

	# Loop similar ao "spawn_blaster_wave" da referência
	for i in range(count):
		var laser = blaster_scene.instantiate()
		get_parent().add_child(laser) # Adiciona ao mundo, não ao Boss
		
		var spawn_pos: Vector2
		var orientation = randi() % 2 # 0 = Horizontal, 1 = Vertical
		
		# Lógica adaptada de "spawn_blaster" usando o RECT como limite
		if orientation == 0: 
			# X é aleatório dentro da largura do retângulo
			var x_pos = randf_range(rect.position.x, rect.end.x)
			var y_pos
			
			if randf() < 0.5:
				# Vem de CIMA (rect.position.y), aponta para BAIXO (90 graus)
				y_pos = rect.position.y
				laser.rotation_degrees = 90
			else:
				# Vem de BAIXO (rect.end.y), aponta para CIMA (270 graus)
				y_pos = rect.end.y
				laser.rotation_degrees = 270
			
			spawn_pos = Vector2(x_pos, y_pos)
			
		else:
			var x_pos
			# Y é aleatório dentro da altura do retângulo
			var y_pos = randf_range(rect.position.y, rect.end.y)
			
			if randf() < 0.5:
				# Vem da ESQUERDA (rect.position.x), aponta para DIREITA (0 graus)
				x_pos = rect.position.x
				laser.rotation_degrees = 0
			else:
				# Vem da DIREITA (rect.end.x), aponta para ESQUERDA (180 graus)
				x_pos = rect.end.x
				laser.rotation_degrees = 180
				
			spawn_pos = Vector2(x_pos, y_pos)

		laser.global_position = spawn_pos
		
		# Pequena pausa entre spawns para não criar todos no mesmo milissegundo
		await get_tree().create_timer(delay).timeout

# -------------------------	--------------------------------
# ATAQUE 2: CTRL+C / CTRL+V (Clones)
# ---------------------------------------------------------
func attack_ctrl_cv():
	current_state = States.CTRL_CV
	
	# Mouse vai até o jogador
	target_position = player.global_position
	await get_tree().create_timer(1.0).timeout
	
	# Efeito visual "Copiar" (Pode ser um Label surgindo escrito "Ctrl+C")
	print("Ctrl+C") 
	
	# Mouse se afasta
	target_position = Vector2(screen_size.x / 2, 100)
	await get_tree().create_timer(0.5).timeout
	
	# Cola as cópias
	for i in range(3): # Cria 3 clones
		print("Ctrl+V")
		var clone_pos = player.global_position + Vector2(randf_range(-200, 200), randf_range(-200, 200))
		target_position = clone_pos # Mouse vai onde vai colar
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
	
	# Mouse vai para o centro
	target_position = screen_size / 2
	await get_tree().create_timer(1.0).timeout
	
	# 1. Cria Zonas Seguras (Ilhas)
	var zone_scene = load("res://Cenas/Fases/Zone.tscn")
	var safe_zones = []
	for i in range(2): # 2 ilhas seguras
		var zone = zone_scene.instantiate() # Use um sprite de circulo branco
		zone.modulate = Color(0, 1, 0, 0.5) # Verde transparente
		zone.global_position = Vector2(randf_range(100, screen_size.x-100), randf_range(100, screen_size.y-100))
		get_parent().add_child(zone)
		safe_zones.append(zone)
	
	# Aviso visual (Tela pisca a cor que vai preencher)
	print("Atenção! Preenchendo...")
	await get_tree().create_timer(2.0).timeout
	
	# 2. Verifica se o jogador está nas zonas seguras
	var is_safe = false
	for zone in safe_zones:
		if player.global_position.distance_to(zone.global_position) < 50: # Raio da zona
			is_safe = true
	
	# 3. Aplica dano se não estiver salvo
	if not is_safe:
		print("DANO DO BALDE!")
		if player.has_method("take_damage"):
			player.take_damage(25)
	
	# Limpa zonas
	for zone in safe_zones:
		zone.queue_free()
		
	_start_next_attack()
