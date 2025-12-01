extends CharacterBody2D

@export var speed: float = 50.0
@onready var ray_frente: RayCast2D = $RayCast_Frente
@onready var ray_parede: RayCast2D = $RayCast_Parede
@export var velocidade_tiro: float = 200.0
var projetil_cena = preload("uid://bgs1gd3re016g")
var girando: bool = false
var em_cooldown: bool = false
var player: Node2D
var attack_cooldown: float = 0

func _ready() -> void:
	player = get_tree().get_first_node_in_group("players")
	add_to_group("inimigo")

func _physics_process(delta: float) -> void:
	if Global.paused:
		return

	if girando or em_cooldown:
		mover_com_imã()
		return

	if ray_frente.is_colliding():
		iniciar_giro(-90)
		return

	if not ray_parede.is_colliding():
		await mover_um_pouco_para_frente(0.1)
		if not em_cooldown: 
			iniciar_giro(90)
		return
	mover_com_imã()
	attack_cooldown += delta
	if (player.global_position - global_position).length() < 500:
		shoot()

func mover_com_imã():
	velocity = (transform.x * speed) + (transform.y * 100)
	move_and_slide()

func iniciar_giro(graus: float):
	girando = true
	em_cooldown = true
	rotation_degrees += graus
	await get_tree().physics_frame 
	girando = false
	await get_tree().create_timer(0.5).timeout
	em_cooldown = false

func mover_um_pouco_para_frente(tempo: float):
	girando = true
	await get_tree().create_timer(tempo).timeout

func shoot():
	if attack_cooldown >= 3:
		for i in range(10):
			var new_bullet = projetil_cena.instantiate()
			new_bullet.global_position = global_position
			var direcao = (player.global_position - global_position).normalized().rotated(deg_to_rad(360.0 / 6.0 * i))
			new_bullet.rotation = direcao.angle()
			new_bullet.velocity = direcao * velocidade_tiro
			get_tree().current_scene.call_deferred("add_child", new_bullet)
			attack_cooldown = 0

func take_damage(_amount: int) -> void:
	queue_free()
