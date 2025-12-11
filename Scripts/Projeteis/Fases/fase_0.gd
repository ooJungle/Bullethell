extends Node2D

@export_multiline var falas_finais: Array[String] = [
	"HAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAH...",
	"HAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAH...",
	"HAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAHAH"
]

@onready var color_rect: ColorRect = $Ambiente/ColorRect
@onready var imagem_final: TextureRect = $Ambiente/ImagemFinal
@onready var control: CanvasLayer = $Control
@onready var audio_stream_player: AudioStreamPlayer = $CanvasLayer/AudioStreamPlayer
@onready var aiquemedo: AudioStreamPlayer = $aiquemedo
@onready var cutscene_pré_final: Node2D = $"Cutscene pré final"
@onready var bossmerro: AudioStreamPlayer = $bossmerro
@onready var risos: AudioStreamPlayer = $risos

func _ready() -> void:
	Global.boss_final_morreu.connect(fimdejogo)
	get_tree().get_root().set_transparent_background(true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true, 0)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true, 0)
	
	if imagem_final:
		imagem_final.visible = false
		imagem_final.modulate.a = 0.0

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
	
	if f1 and f2 and f3:
		if Global.musica_timer:
			Global.musica_timer.stop()
		Global.music_player.stop()
		aiquemedo.play()
		audio_stream_player.play()
		mostrar_imagem_final()
		if not Global.dialogo_final_mostrado:
			iniciar_dialogo_automatico()

func mostrar_imagem_final():
	if not imagem_final: return
	
	imagem_final.visible = true
	imagem_final.modulate.a = 0.0
	
	var tween = create_tween()
	
	tween.tween_property(imagem_final, "modulate:a", 0.5, 2.0)
	tween.tween_interval(4.0)
	tween.tween_property(imagem_final, "modulate:a", 0.0, 2.0)
	
	tween.tween_callback(func(): 
		imagem_final.visible = false
	)
	
func iniciar_dialogo_automatico():
	Global.dialogo_final_mostrado = true
	animar_pulso_final()
	Dialogo.start_dialogue(falas_finais)
	risos.play()

func fimdejogo():
	Hud.visible = false
	get_tree().paused = true
	bossmerro.play()
	cutscene_pré_final.visible = true
	cutscene_pré_final.start_boss_death_sequence()

func animar_pulso_final():
	if not color_rect:
		return
		
	var material = color_rect.material as ShaderMaterial
	if not material:
		return

	var tween = create_tween()
	
	var base_opacity = 0.5
	var peak_opacity = 1.0
	
	for i in range(3):
		tween.tween_property(material, "shader_parameter/vignette_opacity", peak_opacity, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(material, "shader_parameter/vignette_opacity", base_opacity, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
