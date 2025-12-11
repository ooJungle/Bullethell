extends CanvasLayer

@export var tempo: float = 0.0

@onready var fake_cursor = $Control/fakecursor
@onready var button_sim = $Control/CenterContainer/Panel/ButtonSim
@onready var button_nao = $Control/CenterContainer/Panel/ButtonNao
@onready var audioerro: AudioStreamPlayer = $audioerro
@onready var clique: AudioStreamPlayer = $clique

var is_fighting_control: bool = false
var click_pending: bool = false

func _ready():
	set_process(false)
func start_fake_cutscene():
	print("aaq")
	audioerro.play()
	await get_tree().create_timer(tempo).timeout
	
	var mouse_pos = get_viewport().get_mouse_position()
	fake_cursor.global_position = mouse_pos
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	is_fighting_control = true
	set_process(true)

func _process(delta):
	if not is_fighting_control:
		return

	var target_pos = button_sim.global_position + (button_sim.size / 2)
	var lerp_weight = 1.5 * delta 
	
	fake_cursor.global_position = fake_cursor.global_position.lerp(target_pos, lerp_weight)
	
	apply_nao_barrier()

	if fake_cursor.global_position.distance_to(target_pos) < 10.0 and not click_pending:
		click_pending = true
		await get_tree().create_timer(2.0).timeout
		clique.play()
		simulate_click()

func _input(event):
	if is_fighting_control and event is InputEventMouseMotion:
		fake_cursor.global_position += event.relative
		apply_nao_barrier()

func apply_nao_barrier():
	var nao_rect = button_nao.get_global_rect().grow(5.0)
	
	if nao_rect.has_point(fake_cursor.global_position):
		var center_nao = nao_rect.get_center()
		var push_dir = (fake_cursor.global_position - center_nao).normalized()
		
		if push_dir == Vector2.ZERO:
			push_dir = Vector2.UP 
			
		var distance_to_edge = max(nao_rect.size.x, nao_rect.size.y) / 1.5
		fake_cursor.global_position = center_nao + (push_dir * distance_to_edge)

func simulate_click():
	is_fighting_control = false
	set_process(false)
	
	button_sim.button_pressed = true
	await get_tree().create_timer(0.2).timeout
	
	Global.zerou = true
	Global.save()
	Global.creditos()
	get_tree().quit()
