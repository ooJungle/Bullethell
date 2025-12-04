extends Node2D

# --- CONFIGURAÇÕES ---
@export var velocidade_encher: float = 10.0
@export var velocidade_esvaziar: float = 10.0

# --- REFERÊNCIAS ---
@onready var arcos = $ArcosDeOpcoes
@onready var cursor = $Cursor

@onready var barra_red = $Interface/VBoxContainer/BarraVermelha
@onready var barra_blue = $Interface/VBoxContainer/BarraAzul
@onready var barra_green = $Interface/VBoxContainer/BarraVerde

func _ready():
	# Configura as barras para serem suaves (sem degraus)
	configurar_barra(barra_red)
	configurar_barra(barra_blue)
	configurar_barra(barra_green)
	
	if has_node("RodaVisual"):
		$RodaVisual.abertura = 0.0
		var tween = create_tween()
		tween.tween_property($RodaVisual, "abertura", 1.0, 1.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func configurar_barra(barra):
	if barra:
		barra.value = 0
		barra.max_value = 100
		barra.step = 0.0 # <--- O SEGREDO: 0 significa "sem degraus", atualização suave

func _process(delta: float):
	if not arcos or not cursor: return
	
	# 1. Usa a função numérica (0, 1, 2)
	# Certifique-se que o script 'arcos_de_opcoes.gd' tem a função 'detectar_indice_no_mouse'
	var indice = arcos.detectar_indice_no_mouse(cursor.global_position)
	
	# 2. Atualiza cada barra (Índice 0=Red, 1=Blue, 2=Green)
	atualizar_barra(barra_red, indice == 0, delta)
	atualizar_barra(barra_blue, indice == 1, delta)
	atualizar_barra(barra_green, indice == 2, delta)

func atualizar_barra(barra: TextureProgressBar, esta_ativo: bool, delta: float):
	if not barra: return
	
	if esta_ativo:
		barra.value += velocidade_encher * delta
		if barra.value >= 100:
			confirmar_escolha_por_barra(barra)
	else:
		# Agora com step=0, isso vai funcionar mesmo com valores pequenos
		barra.value -= velocidade_esvaziar * delta

func confirmar_escolha_por_barra(barra_cheia):
	var escolha = ""
	if barra_cheia == barra_red: escolha = "Agressivo"
	elif barra_cheia == barra_blue: escolha = "Defensivo"
	elif barra_cheia == barra_green: escolha = "Neutro"
	
	print("ESCOLHA CONFIRMADA: ", escolha)
	
	if has_node("/root/RodaManager"):
		RodaManager.fechar_roda(escolha)
