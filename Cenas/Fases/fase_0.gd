extends Node2D

@export_multiline var falas_finais: Array[String] = [
	"HAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAH...",
	"HAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAH...",
	"HAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAH"
]

func _ready() -> void:
	get_tree().get_root().set_transparent_background(true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true, 0)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true, 0)
	$Timer.start()
	Global.plataforma = false
	
	await get_tree().create_timer(1.0).timeout
	verificar_fim_de_jogo()

func _process(delta: float) -> void:
	var time_remaining: float = max(0.0, $Timer.time_left)	
	
	var total_seconds: int = int(time_remaining)
	var minutes: int = total_seconds / 60
	var seconds: int = total_seconds % 60
	
	$player/Camera2D/Label.text = "%02d:%02d" % [minutes, seconds]
	
func _on_timer_timeout() -> void:
	get_tree().change_scene_to_file("res://Cenas/Menu/WinScene.tscn")

func verificar_fim_de_jogo():
	var f1 = Global.portais_ativos["Fase_espaco"] == false
	var f2 = Global.portais_ativos["Fase_plat"] == false
	var f3 = Global.portais_ativos["Fase_RPG"] == false
	
	if f1 and f2 and f3 and not Global.dialogo_final_mostrado:
		iniciar_dialogo_automatico()

func iniciar_dialogo_automatico():
	Global.dialogo_final_mostrado = true
	Dialogo.start_dialogue(falas_finais)
