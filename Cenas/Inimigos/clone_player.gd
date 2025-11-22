extends CharacterBody2D

@export var speed = 180.0
@export var damage = 15
@export var lifetime = 6.0 # Tempo que o clone vive

@export var player_ref: Node2D = null

func _ready():
	# Visual: Deixa o clone cinza e meio transparente para diferenciar do original
	modulate = Color(0.5, 0.5, 0.5, 0.75)
	
	# Encontra o player na cena
	player_ref = get_node_or_null("/root/Node2D/player")
	if not player_ref:
		player_ref = get_node_or_null("/root/fase_teste/player")
	
	# Configura morte automática
	var timer = Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.connect("timeout", queue_free)
	add_child(timer)
	timer.start()

func _physics_process(_delta):
	if player_ref:
		# Lógica simples de perseguição
		var direction = global_position.direction_to(player_ref.global_position)
		velocity = direction * speed
		move_and_slide()
		
		# Opcional: Virar o sprite
		if velocity.x != 0:
			$sprite.flip_h = velocity.x < 0

func _on_collision_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
