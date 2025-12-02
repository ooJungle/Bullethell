extends Polygon2D

@export var raio: float = 180.0
@export var segmentos: int = 32
# 'set = set_abertura' garante que a forma atualize quando mudamos o valor no Inspector
@export_range(0.0, 1.0) var abertura: float = 0.0 : set = set_abertura

func _ready():
	# CORREÇÃO 1: Começa fechada
	abertura = 0.0 
	atualizar_forma()

func set_abertura(valor):
	abertura = valor
	# Garante que o código só rode se o nó estiver pronto para desenhar
	if is_node_ready():
		atualizar_forma()

func atualizar_forma():
	var novos_pontos = PackedVector2Array()
	var novas_uvs = PackedVector2Array()
	var poligonos_internos = [] # Array para definir os triângulos manualmente
	
	# --- ETAPA 1: GERAR PONTOS ---
	
	# Índice 0: O centro da roda
	novos_pontos.append(Vector2.ZERO)
	novas_uvs.append(Vector2(0.5, 0.5))
	
	# Índices 1 até (segmentos + 1): Pontos da borda
	# Precisamos de N segmentos + 1 ponto para fechar o círculo (ex: 32 segmentos = 33 pontos na borda)
	for i in range(segmentos + 1):
		# Calcula o ângulo atual baseado na abertura
		var angulo_total_atual = TAU * abertura
		var angulo = (float(i) / segmentos) * angulo_total_atual
		angulo -= PI / 2 # Começa de cima
		
		# Cria o ponto físico
		var ponto = Vector2(cos(angulo), sin(angulo)) * raio
		novos_pontos.append(ponto)
		
		# Calcula a UV (Textura) - Baseada sempre no círculo CHEIO
		var angulo_original = (float(i) / segmentos) * TAU - (PI / 2)
		var uv = Vector2(cos(angulo_original), sin(angulo_original)) * 0.5 + Vector2(0.5, 0.5)
		novas_uvs.append(uv)
		
	# --- ETAPA 2: GERAR TRIÂNGULOS (CORREÇÃO DO PISCAR) ---
	# Esta é a parte manual mencionada no vídeo para corrigir a animação
	
	# Agora que temos todos os pontos, criamos os triângulos conectando-os.
	# O ponto 0 é o centro. O ponto 1 é o início da borda.
	for i in range(segmentos):
		# Um triângulo é formado pelo Centro (índice 0), um ponto da borda e o próximo ponto.
		# Exemplo: Triângulo 0 usa os pontos [0, 1, 2]
		# Exemplo: Triângulo 31 usa os pontos [0, 32, 33]
		var indice_ponto_atual = i + 1
		var indice_proximo_ponto = i + 2
		
		# Cria a definição do triângulo
		var triangulo = PackedInt32Array([0, indice_ponto_atual, indice_proximo_ponto])
		poligonos_internos.append(triangulo)

	# Aplica os dados gerados ao nó Polygon2D
	polygon = novos_pontos
	uv = novas_uvs
	polygons = poligonos_internos # <--- Muito importante: aplica os triângulos manuais
