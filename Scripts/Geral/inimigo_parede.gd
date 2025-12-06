extends CharacterBody2D

@export var speed = 60.0
@export var forca_gravidade = 2000.0
@export var velocidade_rotacao = 15.0
@export var velocidade_tiro: float = 200.0

var projetil_cena = preload("uid://bgs1gd3re016g")
var player: Node2D
var attack_cooldown: float = 0

# --- NOVAS VARIÁVEIS PARA ANIMAÇÃO ---
# Verifique se o nome do seu nó é AnimatedSprite2D ou sprite
@onready var sprite: AnimatedSprite2D = $Sprite 
@onready var ray_cast_2d: RayCast2D = $RayCast2D

# Controle para não interromper a animação de tiro
var esta_atirando: bool = false 

func _ready() -> void:
	player = get_tree().get_first_node_in_group("players")
	add_to_group("inimigo")
	
	# Conecta o sinal para saber quando a animação acabou
	if sprite:
		sprite.animation_finished.connect(_on_animation_finished)
		sprite.play("andando") # Começa andando

func _physics_process(delta):
	if "paused" in Global and Global.paused:
		return

	velocity.x = speed
	velocity.y += forca_gravidade * delta
	
	var velocidade_final = velocity.rotated(rotation)
	velocity = velocidade_final
	
	move_and_slide()
	
	velocity = velocity.rotated(-rotation)
	velocity.x = speed
	
	if (is_on_floor() or is_on_wall() or is_on_ceiling()) and get_slide_collision_count() > 0:
		var normal = get_slide_collision(0).get_normal()
		alinharNormal(normal, delta)
	elif ray_cast_2d.is_colliding():
		var normal = ray_cast_2d.get_collision_normal()
		alinharNormal(normal, delta)
	else:
		rotate(deg_to_rad(velocidade_rotacao * 10) * delta)
		
	# --- LÓGICA DE ANIMAÇÃO DE MOVIMENTO ---
	# Só toca a animação de andar se NÃO estiver atirando
	if not esta_atirando and sprite:
		if sprite.animation != "andando":
			sprite.play("andando")
	# ---------------------------------------

	attack_cooldown += delta
	if player and (player.global_position - global_position).length() < 500:
		shoot()

func alinharNormal(normal: Vector2, delta: float):
	var target_rotation = normal.angle() + PI / 2
	rotation = lerp_angle(rotation, target_rotation, velocidade_rotacao * delta)

func shoot():
	if attack_cooldown >= 3:
		# --- ATIVA A ANIMAÇÃO DE TIRO ---
		esta_atirando = true
		if sprite:
			sprite.play("atirando")
		# --------------------------------
		
		for i in range(10):
			var new_bullet = projetil_cena.instantiate()
			new_bullet.global_position = global_position
			var direcao = (player.global_position - global_position).normalized().rotated(deg_to_rad(360.0 / 6.0 * i))
			new_bullet.rotation = direcao.angle()
			new_bullet.velocity = direcao * velocidade_tiro
			get_tree().current_scene.call_deferred("add_child", new_bullet)
			attack_cooldown = 0

# --- FUNÇÃO PARA RESETAR ANIMAÇÃO ---
func _on_animation_finished():
	if sprite.animation == "atirando":
		esta_atirando = false
		sprite.play("andando")

func take_damage(_amount: int) -> void:
	queue_free()
