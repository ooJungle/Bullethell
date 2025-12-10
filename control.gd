extends CanvasLayer

@onready var fake_cursor = $Control/fakecursor
@onready var button_sim = $Control/CenterContainer/Panel/ButtonSim
@onready var button_nao = $Control/CenterContainer/Panel/ButtonNao
@onready var audioerro: AudioStreamPlayer2D = $audioerro

func _ready():
	pass

func start_fake_cutscene():
	audioerro.play()
	var mouse_pos = get_viewport().get_mouse_position()
	fake_cursor.global_position = mouse_pos
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	var target_pos = button_sim.global_position + (button_sim.size / 2)
	var tween = create_tween()
	tween.tween_property(fake_cursor, "global_position", target_pos, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(simulate_click)

func simulate_click():
	button_sim.button_pressed = true
	await get_tree().create_timer(0.2).timeout
	Global.zerou = true
	Global.save()
	Global.creditos()
	get_tree().quit()
	
