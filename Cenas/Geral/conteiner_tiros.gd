@tool
extends Polygon2D

# Configurações do Círculo
@export var raio: float = 175.0 : set = set_raio
@export var suavidade: int = 64 : set = set_suavidade # Quantos "lados" o círculo tem

func set_raio(valor):
	raio = valor
	gerar_forma()

func set_suavidade(valor):
	suavidade = valor
	gerar_forma()

func _ready():
	gerar_forma()

func gerar_forma():
	var pontos = PackedVector2Array()
	
	# Gera os pontos ao redor do centro (0,0)
	for i in range(suavidade + 1):
		var angulo = (float(i) / suavidade) * TAU # TAU é 2*PI (360 graus)
		var ponto = Vector2(cos(angulo), sin(angulo)) * raio
		pontos.append(ponto)
	
	# Aplica os pontos à propriedade nativa do Polygon2D
	polygon = pontos
