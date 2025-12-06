extends Node2D

# --- CONFIGURAÇÕES ---
@export var velocidade_encher: float = 15.0
@export var velocidade_esvaziar: float = 10.0

@onready var arcos = $ArcosDeOpcoes
@onready var cursor = $Cursor

# Referências das barras
@onready var barra_red = $Interface/VBoxContainer/GrupoAgressivo/BarraVermelha
@onready var barra_green = $Interface/VBoxContainer/GrupoDefensivo/BarraVerde
# Referências das Labels (para brilho)
@onready var label_red = $Interface/VBoxContainer/GrupoAgressivo/LabelAgressivo
@onready var label_blue = $Interface/VBoxContainer/GrupoNeutro/LabelNeutro
@onready var label_green = $Interface/VBoxContainer/GrupoDefensivo/LabelDefensivo

func _ready():
	configurar_barra(barra_red)
	configurar_barra(barra_green)
	
	# Animação de entrada
	if has_node("RodaVisual"):
		$RodaVisual.abertura = 0.0
		var tween = create_tween()
		tween.tween_property($RodaVisual, "abertura", 1.0, 1.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func configurar_barra(barra):
	if barra:
		barra.value = 0
		barra.max_value = 100
		barra.step = 0.0 

func _process(delta: float):
	if not arcos or not cursor: return
	
	# Detecta índice (0, 1 ou 2)
	var indice = arcos.detectar_indice_no_mouse(cursor.global_position)
	
	atualizar_conjunto(barra_red, label_red, indice == 0, delta)
	atualizar_conjunto(barra_green, label_green, indice == 1, delta)

func atualizar_conjunto(barra, label, esta_ativo, delta):
	if not barra: return
	
	if esta_ativo:
		barra.value += velocidade_encher * delta
		if label: label.modulate = Color.YELLOW # Destaque
		
		if barra.value >= 100:
			confirmar_escolha_por_indice(barra)
	else:
		barra.value -= velocidade_esvaziar * delta
		if label: label.modulate = Color.WHITE

func confirmar_escolha_por_indice(barra_cheia):
	var indice_escolhido = -1
	
	if barra_cheia == barra_red: indice_escolhido = 0
	elif barra_cheia == barra_green: indice_escolhido = 1
	
	# Pega o nome REAL que está configurado no Inspector do filho
	# Usamos .get() para evitar crashes se o Godot se perder no tipo
	var opcoes = arcos.get("opcoes_config")
	var nome_escolha = "Desconhecido"
	
	if opcoes and indice_escolhido >= 0 and indice_escolhido < opcoes.size():
		nome_escolha = opcoes[indice_escolhido]["nome"]
	
	print("ESCOLHA FINAL: ", nome_escolha)
	
	if has_node("/root/RodaManager"):
		RodaManager.fechar_roda(nome_escolha)
