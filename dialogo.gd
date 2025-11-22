extends CanvasLayer

@onready var background = $ColorRect
@onready var text_label = $ColorRect/RichTextLabel

var dialogos: Array[String] = []
var indice_atual: int = 0
var is_active: bool = false
var pode_avancar: bool = true

func _ready():
	visible = false

func start_dialogue(linhas_de_texto: Array[String]):
	if is_active:
		return
	
	dialogos = linhas_de_texto
	indice_atual = 0
	is_active = true
	visible = true
	
	# Opcional: Pausa o jogo/player enquanto fala
	Global.paused = true 
	
	mostrar_texto_atual()

func mostrar_texto_atual():
	if indice_atual >= dialogos.size():
		fechar_dialogo()
		return
	
	text_label.text = dialogos[indice_atual]
	text_label.visible_ratio = 0.0
	pode_avancar = false
	
	# Efeito de digitação (Tween)
	var tween = create_tween()
	var tempo = text_label.text.length() * 0.05 # Velocidade da digitação
	tween.tween_property(text_label, "visible_ratio", 1.0, tempo)
	tween.finished.connect(func(): pode_avancar = true)

func _unhandled_input(event):
	if not is_active:
		return
		
	if event.is_action_pressed("ui_accept") and is_active:
		if pode_avancar:
			indice_atual += 1
			mostrar_texto_atual()
		else:
			# Se apertar enquanto digita, termina o texto instantaneamente
			var tween = get_tree().create_tween() # Mata o tween anterior
			text_label.visible_ratio = 1.0
			pode_avancar = true

func fechar_dialogo():
	visible = false
	is_active = false
	Global.paused = false
