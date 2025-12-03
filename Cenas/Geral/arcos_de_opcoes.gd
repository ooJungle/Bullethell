@tool
extends Node2D

# --- Configurações Visuais dos Arcos ---
@export_group("Geometria dos Arcos")
@export var raio: float = 130.0:
	set(v): raio = v; queue_redraw()
@export var espessura: float = 25.0:
	set(v): espessura = v; queue_redraw()
@export_range(0.0, 0.5) var espacamento_padding: float = 0.05:
	set(v): espacamento_padding = v; queue_redraw()
@export var segmentos_suavidade: int = 64

# --- Configurações das Linhas Divisórias (NOVO) ---
@export_group("Divisórias")
@export var desenhar_linhas: bool = true:
	set(v): desenhar_linhas = v; queue_redraw()
@export var cor_linha: Color = Color.BLACK:
	set(v): cor_linha = v; queue_redraw()
@export var espessura_linha: float = 3.0:
	set(v): espessura_linha = v; queue_redraw()

# --- Definição das Opções ---
@export_group("Opções")
@export var opcoes_config: Array[Dictionary] = [
	{"cor": Color.TOMATO, "nome": "Agressivo"}, 
	{"cor": Color.CORNFLOWER_BLUE, "nome": "Defensivo"},
	{"cor": Color.LIME_GREEN, "nome": "Neutro"}
]: set = set_opcoes_config


func _draw() -> void:
	var qtd_opcoes = opcoes_config.size()
	if qtd_opcoes == 0: return
	
	var angulo_total_por_opcao = TAU / qtd_opcoes
	var largura_angular_arco = angulo_total_por_opcao - (espacamento_padding * 2)
	
	# Gira para começar do topo (-90 graus)
	var rotacao_inicial = -PI / 2 
	
	# 1. DESENHA OS ARCOS COLORIDOS
	for i in range(qtd_opcoes):
		var angulo_centro_opcao = (i * angulo_total_por_opcao) + rotacao_inicial
		var angulo_inicio = angulo_centro_opcao - (largura_angular_arco / 2.0)
		var angulo_fim = angulo_inicio + largura_angular_arco
		
		var cor_arco = opcoes_config[i].get("cor", Color.WHITE)
		
		draw_arc(Vector2.ZERO, raio, angulo_inicio, angulo_fim, segmentos_suavidade, cor_arco, espessura, true)

	# 2. DESENHA AS LINHAS DIVISÓRIAS (NOVO)
	if desenhar_linhas:
		# Calcula até onde a linha vai (borda externa do arco)
		var raio_externo = raio + (espessura / 2.0)
		
		for i in range(qtd_opcoes):
			# Calcula o ângulo EXATAMENTE entre duas opções
			# (Centro da opção atual + metade do tamanho dela)
			var angulo_divisoria = (i * angulo_total_por_opcao) + rotacao_inicial + (angulo_total_por_opcao / 2.0)
			
			# Cria o vetor de direção
			var direcao = Vector2(cos(angulo_divisoria), sin(angulo_divisoria))
			
			# Define ponto inicial (centro) e final (borda)
			var ponto_inicial = Vector2.ZERO
			var ponto_final = direcao * raio_externo
			
			draw_line(ponto_inicial, ponto_final, cor_linha, espessura_linha)

func set_opcoes_config(valor):
	opcoes_config = valor
	queue_redraw()
