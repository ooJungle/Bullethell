extends CharacterBody2D

@export var speed = 180.0
@export var damage = 15
@export var lifetime = 6.0 # Tempo que o clone vive
@export var vida = 2
@export var player_ref: Node2D = null
@onready var dano_timer: Timer = $dano_timer

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
	if player_ref.global_position - global_position < Vector2(20, 20):
		player_ref.take_damage(damage)
		queue_free()
		
func take_damage(_amount: int) -> void:
	dano_timer.start(0.3)
	modulate = Color(1.0, 0.502, 0.502, 0.749)
	vida -= 1
	if vida <= 0:
		queue_free()	

func _on_dano_timer_timeout() -> void:
	modulate = Color(0.5, 0.5, 0.5, 0.75)
