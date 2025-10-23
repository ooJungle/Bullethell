extends Node2D

@export var aim_duration: float = 0.75
@export var laser_duration: float = 1.0
@export var laser_width: float = 10.0
@export var horizontal_laser_length: float = 1200.0
@export var vertical_laser_length: float = 2400.0
var orientation: String = "horizontal" 

@onready var sprite = $Sprite2D
@onready var laser_ray = $LaserArea/RayCast2D
@onready var laser_area = $LaserArea
@onready var laser_line: Line2D = $LaserArea/Line2D
@onready var laser_colision = $LaserArea/CollisionShape2D
@onready var aim_line: Line2D = $AimLine

func _ready():
	laser_area.add_to_group("laser")
	if laser_line:
		laser_line.visible = false
		laser_line.width = laser_width
		laser_line.default_color = Color(1, 0, 0, 1)

	if aim_line:
		aim_line.visible = true 
		aim_line.width = 3.0
		aim_line.default_color = Color(0.2, 0.4, 1, 0.6) 

		var laser_length: float
		match orientation:
			"horizontal":
				laser_length = horizontal_laser_length
			"vertical":
				laser_length = vertical_laser_length
			"diagonal":
				laser_length = horizontal_laser_length
		aim_line.points = [Vector2.ZERO, Vector2(laser_length, 0)]

	start_aiming_and_fire()

func start_aiming_and_fire():
	var laser_length: float
	match orientation:
		"horizontal":
			laser_length = horizontal_laser_length
		"vertical":
			laser_length = vertical_laser_length
		"diagonal":
			laser_length = horizontal_laser_length
	
	laser_ray.target_position = Vector2(laser_length, 0)
	laser_line.points[1] = Vector2(laser_length, 0)
		
	await get_tree().create_timer(aim_duration).timeout
	
	if aim_line:
		aim_line.visible = false
		
	fire_laser()

func fire_laser():
	laser_ray.enabled = true
	if laser_line:
		laser_line.visible = true
		laser_line.points = [Vector2.ZERO, laser_ray.target_position]
	
	laser_ray.force_raycast_update()
	
	await get_tree().create_timer(laser_duration).timeout
	
	laser_ray.enabled = false
	if laser_line:
		laser_line.visible = false
	queue_free()

func set_orientation(type: String):
	orientation = type
	
func _process(delta: float) -> void:
	if Global.paused:
		return
