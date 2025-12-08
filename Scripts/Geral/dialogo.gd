extends CanvasLayer

signal finished 

@onready var background = $ColorRect
@onready var text_label = $ColorRect/RichTextLabel
@onready var color_rect_2 = $ColorRect2 # Tela de Tutorial
@onready var rich_text_label_2 = $ColorRect2/RichTextLabel2

var dialogos: Array[String] = []
var indice_atual: int = 0
var is_active: bool = false
var pode_avancar: bool = true
var tutorial: bool = false

# Nova variável para controlar o estado
var exibindo_tutorial: bool = false 

var current_tween: Tween 

func _ready():
	visible = false
	color_rect_2.visible = false

func start_dialogue(linhas_de_texto: Array[String]):
	if is_active:
		return

	# Resetamos o estado visual
	background.visible = true       # Mostra a caixa de texto
	color_rect_2.visible = false    # Esconde o tutorial (por enquanto)
	exibindo_tutorial = false       # Garante que não comece no estado de tutorial

	dialogos = linhas_de_texto
	indice_atual = 0
	is_active = true
	visible = true
	
	Global.paused = true 
	
	mostrar_texto_atual()

func mostrar_texto_atual():
	# Se o texto acabou...
	if indice_atual >= dialogos.size():
		if tutorial:
			# Se tiver tutorial ativado, mostramos ele AGORA
			mostrar_tela_tutorial()
		else:
			# Se não, fecha normal
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

# Nova função para trocar do texto para o tutorial
func mostrar_tela_tutorial():
	exibindo_tutorial = true
	background.visible = false   # Esconde o texto
	color_rect_2.visible = true  # Mostra o tutorial instantaneamente
	# O jogo continua pausado (Global.paused = true) esperando o input

func _unhandled_input(event):
	if not is_active:
		return
		
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interagir"): # Adicionei 'interagir' por segurança
		
		# --- LÓGICA DO TUTORIAL ---
		if exibindo_tutorial:
			fechar_dialogo()
			return # Para a execução aqui
		# --------------------------

		# Lógica Normal de Texto
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
	
	# Reseta estados visuais
	background.visible = true
	color_rect_2.visible = false
	exibindo_tutorial = false
	tutorial = false # Reseta a flag para o próximo diálogo não abrir tutorial sem querer
	
	Global.paused = false
	
	finished.emit()
