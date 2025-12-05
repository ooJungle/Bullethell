extends PanelContainer

# --- CORREÇÃO AQUI ---
# Deixe o array vazio: []
# Nós vamos preencher isso clicando no Inspector do Godot.
@export var itens_legenda: Array[DadosLegenda] = []

@onready var lista_container = $VBoxContainer

func _ready():
	for child in lista_container.get_children():
		child.queue_free()
	
	for item in itens_legenda:
		criar_linha(item)

func criar_linha(dados: DadosLegenda): # Note o tipo DadosLegenda aqui também
	var linha = HBoxContainer.new()
	linha.add_theme_constant_override("separation", 10)
	
	var icone = TextureRect.new()
	# Agora acessamos direto com ponto (.) porque é um objeto, não um dicionário
	icone.texture = dados.textura 
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icone.custom_minimum_size = Vector2(32, 32)
	
	var texto = Label.new()
	texto.text = dados.descricao
	texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	linha.add_child(icone)
	linha.add_child(texto)
	lista_container.add_child(linha)
