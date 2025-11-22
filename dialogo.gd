extends CanvasLayer

signal finished 

@onready var background = $ColorRect
@onready var text_label = $ColorRect/RichTextLabel

var dialogos: Array[String] = []
var indice_atual: int = 0
var is_active: bool = false
var pode_avancar: bool = true

var current_tween: Tween 

func _ready():
	visible = false

func start_dialogue(linhas_de_texto: Array[String]):
	if is_active:
		return
	
	dialogos = linhas_de_texto
	indice_atual = 0
	is_active = true
	visible = true
	
	Global.paused = true 
	
	mostrar_texto_atual()

func mostrar_texto_atual():
	if indice_atual >= dialogos.size():
		fechar_dialogo()
		return
	
	text_label.text = dialogos[indice_atual]
	text_label.visible_ratio = 0.0
	pode_avancar = false
	
	if current_tween:
		current_tween.kill()
	
	current_tween = create_tween()
	var tempo = text_label.text.length() * 0.05 
	current_tween.tween_property(text_label, "visible_ratio", 1.0, tempo)
	current_tween.finished.connect(func(): pode_avancar = true)

func _unhandled_input(event):
	if not is_active:
		return
		
	if event.is_action_pressed("ui_accept") and is_active:
		if pode_avancar:
			indice_atual += 1
			mostrar_texto_atual()
		else:
			if current_tween:
				current_tween.kill()
			
			text_label.visible_ratio = 1.0
			pode_avancar = true

func fechar_dialogo():
	visible = false
	is_active = false
	Global.paused = false
	
	finished.emit()
