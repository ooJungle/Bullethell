extends CharacterBody2D

@export var velocidade = 120.0
@export var gravidade_z: float = 900.0
@export var forca_pulo: float = 350.0
@export var distancia_ativacao: float = 450.0 

var player: Node2D
var altura_z: float = 0.0
var velocidade_z: float = 0.0
var tempo_para_pulo: float = 0.0

@onready var visual_node: Node2D = $Visual
@onready var sombra_sprite: Sprite2D = $Sombra
@onready var sprite: AnimatedSprite2D = $Visual/Sprite

func _ready() -> void:
	add_to_group("inimigo")
	player = get_tree().get_first_node_in_group("players")
	tempo_para_pulo = randf_range(1.0, 3.0)

func _physics_process(delta: float) -> void:
	if Global.paused: return

	atualizar_fisica_z(delta)

	if altura_z > 0:
		if is_instance_valid(player):
			var direcao = (player.global_position - global_position).normalized()
			velocity = direcao * velocidade * Global.fator_tempo
			if direcao.x != 0:
				sprite.flip_h = direcao.x < 0
	else:
		velocity = Vector2.ZERO
		controlar_tempo_pulo(delta)

	move_and_slide()
	atualizar_visual() 
	atualizar_animacao()

func atualizar_fisica_z(delta: float):
	if altura_z > 0 or velocidade_z != 0:
		velocidade_z -= gravidade_z * delta * Global.fator_tempo
		altura_z += velocidade_z * delta * Global.fator_tempo
		
		if altura_z <= 0:
			altura_z = 0
			velocidade_z = 0

func controlar_tempo_pulo(delta: float):
	if not is_instance_valid(player): return
	
	var distancia = global_position.distance_to(player.global_position)
	if distancia < distancia_ativacao:
		tempo_para_pulo -= delta * Global.fator_tempo
		if tempo_para_pulo <= 0:
			velocidade_z = forca_pulo
			tempo_para_pulo = randf_range(1.5, 3.0)

func atualizar_visual():
	visual_node.position.y = -altura_z
	
	var scale_factor = remap(altura_z, 0, 200, 1.0, 0.5)
	sombra_sprite.scale = Vector2(scale_factor, scale_factor)
	
	z_index = 10 if altura_z > 10 else 0

func atualizar_animacao():
	if altura_z > 0:
		sprite.play("pulo")
	else:
		sprite.play("idle")

func take_damage(amount: int) -> void:
	queue_free()
