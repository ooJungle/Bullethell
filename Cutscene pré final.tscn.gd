extends Node

@onready var white_screen: ColorRect = $CanvasLayer/ColorRect
@onready var meta_text: Label = $CanvasLayer/Label
@onready var control: CanvasLayer = $"../Control"

func _ready() -> void:
	white_screen.modulate.a = 0.0
	meta_text.modulate.a = 0.0

func start_boss_death_sequence():
	print("aqui")
	var tween = create_tween()
	tween.tween_property(white_screen, "modulate:a", 1.0, 3.0)
	
	await tween.finished

	await get_tree().create_timer(1.0).timeout
	await mostrar_texto("Parece que acabou...")
	await get_tree().create_timer(1.0).timeout 
	await mostrar_texto("Você venceu....")
	await get_tree().create_timer(1.0).timeout
	await mostrar_texto("O que está esperando?")
	await get_tree().create_timer(1.5).timeout

	var nome_usuario = pegar_nome_usuario_os()

	await mostrar_texto("Você sabe o que tem que fazer, " + nome_usuario, false)

	tocar_cutscene_final()

func mostrar_texto(texto: String, deve_sumir: bool = true):
	meta_text.text = texto
	
	var tween = create_tween()
	tween.tween_property(meta_text, "modulate:a", 1.0, 1.5)
	tween.tween_interval(2.0)
	
	if deve_sumir:
		tween.tween_property(meta_text, "modulate:a", 0.0, 1.5)
	
	await tween.finished

func pegar_nome_usuario_os() -> String:
	return "jogador"

func tocar_cutscene_final():
	control.visible = true
	control.start_fake_cutscene()
