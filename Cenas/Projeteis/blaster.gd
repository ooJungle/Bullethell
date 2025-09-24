extends Node2D

var target_player: CharacterBody2D  # Setado externamente pelo spawner
@export var laser_duration: float = 1.0  # Tempo do laser ativo
@export var aim_speed: float = 20.0  # Velocidade de rotação para mirar
@export var damage_interval: float = 0.2  # Dano a cada 0.2s enquanto colidindo
@export var tracking_speed: float = 1.0  # Rotação sutil durante disparo (tracking)
@export var laser_width: float = 5.0  # Largura base do laser visual

@onready var sprite = $Sprite2D
@onready var laser_ray = $LaserArea/RayCast2D
@onready var laser_area = $LaserArea
@onready var laser_line: Line2D = $LaserArea/LaserLine  # NOVO: Referência ao visual

var pulse_tween: Tween  # Para efeito de pulsar a largura (opcional)

func _ready():
	target_player = get_parent().get_parent().get_node("player")
	
	laser_area.add_to_group("laser")
	laser_ray.enabled = false
	if laser_line:
		laser_line.visible = false
		laser_line.width = laser_width
		laser_line.default_color = Color(1, 0, 0, 1)  # Vermelho (pode exportar para inspector)
	else:
		push_warning("Blaster: LaserLine não encontrado na cena! Adicione um Line2D em LaserArea.")

	rotation = 0

func shoot_laser():
	if not target_player:
		push_warning("Blaster: Não é possível disparar - target_player é null!")
		queue_free()
		return
	
	# Mira o player gradualmente (carregamento)
	var tween = create_tween()
	var initial_target_angle = (target_player.global_position - global_position).angle()
	tween.tween_method(_rotate_to_angle, rotation, initial_target_angle, aim_speed / 10.0)
	
	await tween.finished
	
	# Dispara o laser: Ativa colisão E visual
	laser_ray.enabled = true
	if laser_line:
		laser_line.visible = true
		laser_line.points = [Vector2(0, 0), laser_ray.target_position]  # Sincroniza com o ray
		# Efeito de pulsar (opcional: faz a largura variar para "vivo")
		_start_pulse_effect()
	
	laser_ray.force_raycast_update()
	
	# Rotação sutil de tracking durante o laser
	var track_tween = create_tween()
	track_tween.set_loops()
	track_tween.tween_method(_track_player, 0.0, 1.0, laser_duration / aim_speed)
	
	# Desativa após duração
	await get_tree().create_timer(laser_duration).timeout
	laser_ray.enabled = false
	if laser_line:
		laser_line.visible = false
		_stop_pulse_effect()
	track_tween.kill()
	queue_free()

func _track_player(_progress: float):
	if target_player and laser_line:
		var new_angle = (target_player.global_position - global_position).angle()
		rotation = lerp_angle(rotation, new_angle, tracking_speed * get_process_delta_time())
		# Atualiza points do laser para seguir a rotação (mas como é filho, herda automaticamente)
		laser_line.points = [Vector2(0, 0), laser_ray.target_position]

# Efeito de pulsar (opcional: anima a largura para simular energia)
func _start_pulse_effect():
	if not laser_line:
		return
	pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(laser_line, "width", laser_width * 1.5, 0.3)
	pulse_tween.tween_property(laser_line, "width", laser_width, 0.3)

func _stop_pulse_effect():
	if pulse_tween:
		pulse_tween.kill()

func _rotate_to_angle(current: float, target: float):
	# Lerp angular suave
	var diff = fmod(target - current + PI, 2 * PI) - PI
	rotation += diff * 0.1
