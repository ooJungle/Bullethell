extends Node2D

@export var aim_duration: float = 0.75
@export var laser_duration: float = 1.0
@export var laser_width: float = 10.0
@export var horizontal_laser_length: float = 1200.0 # Comprimento para tiros de cima/baixo
@export var vertical_laser_length: float = 2400.0   # Comprimento para tiros da esquerda/direita
var orientation: String = "horizontal" 

@onready var sprite = $Sprite2D
@onready var laser_ray = $LaserArea/RayCast2D
@onready var laser_area = $LaserArea
@onready var laser_line: Line2D = $LaserArea/Line2D
@onready var laser_colision = $LaserArea/CollisionShape2D

func _ready():
	laser_area.add_to_group("laser")
	if laser_line:
		laser_line.visible = false
		laser_line.width = laser_width
		laser_line.default_color = Color(1, 0, 0, 1)

	# Inicia o processo de mirar, e depois atirar
	start_aiming_and_fire()

func start_aiming_and_fire():
	if orientation == "vertical":
		laser_ray.target_position.x = vertical_laser_length
		laser_line.points[1].x = vertical_laser_length
	else:
		laser_ray.target_position.x = horizontal_laser_length
		laser_line.points[1].x = horizontal_laser_length
		
	# 1. Espera pela duração da mira (enquanto isso, _process vai rotacionar)
	await get_tree().create_timer(aim_duration).timeout
	
	# 2. Trava a mira e dispara
	fire_laser()

func fire_laser():
	# Ativa o laser visual e a colisão
	laser_ray.enabled = true
	if laser_line:
		laser_line.visible = true
		laser_line.points = [Vector2.ZERO, laser_ray.target_position]
	
	laser_ray.force_raycast_update()
	
	# 3. Espera a duração do laser
	await get_tree().create_timer(laser_duration).timeout
	
	# 4. Desliga tudo e se destrói
	laser_ray.enabled = false
	if laser_line:
		laser_line.visible = false
	queue_free()

# O Spawner chama esta função para nos dizer qual o tipo de tiro
func set_orientation(type: String):
	orientation = type
	
func _process(delta: float) -> void:
	if Global.paused:
		return
