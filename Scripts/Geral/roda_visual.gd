extends Polygon2D

@export var raio: float = 180.0
@export var segmentos: int = 32
@export_range(0.0, 1.0) var abertura: float = 0.0 : set = set_abertura

# --- NOVA VARIÁVEL ---
# Coloque aqui o tamanho exato do seu SubViewport ou da sua Imagem (ex: 512, 512)
@export var tamanho_textura: Vector2 = Vector2(512, 512) 

func _ready():
	abertura = 0.0 
	atualizar_forma()

func set_abertura(valor):
	abertura = valor
	if is_node_ready():
		atualizar_forma()

func atualizar_forma():
	var novos_pontos = PackedVector2Array()
	var novas_uvs = PackedVector2Array()
	var poligonos_internos = []
	
	# --- ETAPA 1: GERAR PONTOS ---
	
	# Centro (Ponto 0)
	novos_pontos.append(Vector2.ZERO)
	
	# UV do Centro: Metade do tamanho da textura (ex: 256, 256)
	novas_uvs.append(tamanho_textura * 0.5)
	
	for i in range(segmentos + 1):
		# Posição Física (Vértice)
		var angulo_total_atual = TAU * abertura
		var angulo = (float(i) / segmentos) * angulo_total_atual
		angulo -= PI / 2 
		
		var ponto = Vector2(cos(angulo), sin(angulo)) * raio
		novos_pontos.append(ponto)
		
		# --- CORREÇÃO DA UV (TEXTURA) ---
		var angulo_original = (float(i) / segmentos) * TAU - (PI / 2)
		
		# 1. Calcula de -0.5 a 0.5
		var uv_normalizada = Vector2(cos(angulo_original), sin(angulo_original)) * 0.5
		
		# 2. Centraliza (0.0 a 1.0)
		uv_normalizada += Vector2(0.5, 0.5)
		
		# 3. Converte para PIXELS (0 a 512)
		var uv_final = uv_normalizada * tamanho_textura
		
		novas_uvs.append(uv_final)
		
	# --- ETAPA 2: TRIÂNGULOS ---
	for i in range(segmentos):
		var indice_ponto_atual = i + 1
		var indice_proximo_ponto = i + 2
		var triangulo = PackedInt32Array([0, indice_ponto_atual, indice_proximo_ponto])
		poligonos_internos.append(triangulo)

	polygon = novos_pontos
	uv = novas_uvs
	polygons = poligonos_internos
