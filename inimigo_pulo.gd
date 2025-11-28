extends CharacterBody2D

@export var velocidade = 100.0
@export var player: Node2D
@export var gravidade_z: float = 900.0
@export var forca_pulo: float = 350.0

var altura_z: float = 0.0
var velocidade_z: float = 0.0

@onready var visual_node: Node2D = $Visual
@onready var sombra_sprite: Sprite2D = $Sombra
@onready var sprite: AnimatedSprite2D = $Visual/Sprite

var tempo_para_pulo: float = 0.0

func _ready() -> void:
	player = get_tree().get_first_node_in_group("players")
	tempo_para_pulo = randf_range(2.0, 4.0)

func _physics_process(delta: float) -> void:
	if Global.paused: return

	if altura_z > 0:
		if is_instance_valid(player):
			var direcao = (player.global_position - global_position).normalized()
			velocity = direcao * velocidade * Global.fator_tempo
		else:
			velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO

	processar_pulo(delta)
	controlar_ia_pulo(delta)

	move_and_slide()
	update_animation()

func processar_pulo(delta: float):
	if altura_z > 0 or velocidade_z != 0:
		velocidade_z -= gravidade_z * delta * Global.fator_tempo
		altura_z += velocidade_z * delta * Global.fator_tempo
		
		if altura_z <= 0:
			altura_z = 0
			velocidade_z = 0
			aterrissar()

	visual_node.position.y = -altura_z
	
	var scale_factor = remap(altura_z, 0, 200, 1.0, 0.5)
	sombra_sprite.scale = Vector2(scale_factor, scale_factor)
	
	z_index = 10 if altura_z > 10 else 0

func pular():
	if altura_z == 0:
		velocidade_z = forca_pulo

func aterrissar():
	pass

func controlar_ia_pulo(delta: float):
	if altura_z == 0:
		tempo_para_pulo -= delta * Global.fator_tempo
		if tempo_para_pulo <= 0:
			pular()
			tempo_para_pulo = randf_range(2.0, 5.0)

func update_animation():
	if altura_z > 0:
		if velocidade_z < 0:
			sprite.play("aterrissando")
		else:
			sprite.play("pulo")
	else:
		sprite.play("idle")
	
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0
