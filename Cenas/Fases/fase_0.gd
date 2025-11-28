extends Node2D

@export_multiline var falas_finais: Array[String] = [
	"HAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAH...",
	"HAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAH...",
	"HAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAH"
]

@onready var color_rect: ColorRect = $Ambiente/ColorRect

func _ready() -> void:
	get_tree().get_root().set_transparent_background(true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true, 0)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true, 0)
	
	$Timer.start()
	Global.plataforma = false
	
	await get_tree().create_timer(1.0).timeout
	verificar_fim_de_jogo()
	
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
	
	# Chama o efeito visual
	animar_pulso_final()
	
	Dialogo.start_dialogue(falas_finais)

# --- FUNÇÃO DO EFEITO VISUAL ---
func animar_pulso_final():
	if not color_rect:
		return
		
	var material = color_rect.material as ShaderMaterial
	if not material:
		return

	var tween = create_tween()
	
	# Configuração dos valores da vinheta (ajuste se necessário)
	var base_opacity = 0.5
	var peak_opacity = 1.0 # Escurece totalmente as bordas
	
	# Cria a sequência de 3 pulsos
	for i in range(3):
		# 1. Escurece (Aumenta opacidade da vinheta)
		tween.tween_property(material, "shader_parameter/vignette_opacity", peak_opacity, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		# 2. Clareia (Volta ao normal)
		tween.tween_property(material, "shader_parameter/vignette_opacity", base_opacity, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
