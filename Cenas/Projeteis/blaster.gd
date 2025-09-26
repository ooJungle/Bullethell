extends Node2D

var target_player: CharacterBody2D  # Setado externamente pelo spawner
@export var laser_duration: float = 1.0  # Tempo do laser ativo
@export var aim_speed: float = 20.0  # Velocidade de rotação para mirar
@export var damage_interval: float = 0.2  # Dano a cada 0.2s enquanto colidindo
@export var tracking_speed: float = 1.0  # Rotação sutil durante disparo (tracking)
@export var laser_width: float = 5.0  # Largura base do laser visual

@onready var sprite = $Sprite2D
var original_sprite_scale: Vector2

@onready var laser_ray = $LaserArea/RayCast2D
@onready var laser_area = $LaserArea
@onready var laser_line: Line2D = $LaserArea/Line2D

func _ready():
	target_player = get_parent().get_parent().get_node("player")
	
	original_sprite_scale = sprite.scale  # Salva escala original

	laser_area.add_to_group("laser")
	laser_ray.enabled = false
	if laser_line:
		laser_line.visible = false
		laser_line.width = laser_width
		laser_line.default_color = Color(1, 0, 0, 1)  # Vermelho (pode exportar para inspector)
	else:
		push_warning("Blaster: LaserLine não encontrado na cena! Adicione um Line2D em LaserArea.")
	
	rotation = 0
	
	# Dispara o laser: Ativa colisão E visual
	laser_ray.enabled = true
	if laser_line:
		laser_line.visible = true
		laser_line.points = [Vector2(0, 0), laser_ray.target_position]  # Sincroniza com o ray
	
	laser_ray.force_raycast_update()

	# Desativa após duração
	await get_tree().create_timer(laser_duration).timeout
	laser_ray.enabled = false
	if laser_line:
		laser_line.visible = false
	queue_free()

# Detecta se precisa flipar o sprite (para spawns abaixo)
func _process(delta: float) -> void:
	if not target_player:
		return
	var relative_pos = target_player.global_position - global_position
	if relative_pos.y < 0:  # Player está acima (spawn abaixo) - flip para "virar" a caveira
		sprite.scale.y = -original_sprite_scale.y  # Flip horizontal
		print("Blaster: Flip aplicado (spawn abaixo do player)")
	else:
		sprite.scale.y = original_sprite_scale.y  # Sem flip

	if target_player and laser_line:
		if (position.y > 0):
			laser_line.scale.y = -abs(laser_line.scale.y)
		else:
			laser_line.scale.y = abs(laser_line.scale.y)
