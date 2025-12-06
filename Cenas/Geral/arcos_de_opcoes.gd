class_name ArcosDeOpcoes
extends Node2D

@export var velocidade_rotacao: float = 0.5

# --- VISUAL ---
@export_group("Geometria")
@export var raio: float = 130.0:
	set(v): raio = v; queue_redraw()
@export var espessura: float = 25.0:
	set(v): espessura = v; queue_redraw()
@export var padding: float = 0.05:
	set(v): padding = v; queue_redraw()
@export var suavidade: int = 64

@export_group("Divisórias")
@export var desenhar_linhas: bool = true:
	set(v): desenhar_linhas = v; queue_redraw()
@export var cor_linha: Color = Color.BLACK
@export var espessura_linha: float = 3.0

# --- NOVO: CONFIGURAÇÕES DE TEXTO ---
@export_group("Texto")
# Arraste um arquivo de fonte (.ttf, .otf) aqui no Inspector.
# Se deixar vazio, ele tentará usar uma fonte padrão do sistema.
@export var fonte: Font
@export var tamanho_fonte: int = 25:
	set(v): tamanho_fonte = v; queue_redraw()
@export var cor_texto: Color = Color.BLACK:
	set(v): cor_texto = v; queue_redraw()
# Use o offset para empurrar o texto para dentro (negativo) ou fora (positivo) do círculo central
@export var offset_texto: float = 30.0: 
	set(v): offset_texto = v; queue_redraw()

# --- OPÇÕES (Agora baseadas em Porcentagem 0-100) ---
@export_group("Opções")
@export var opcoes_config: Array[Dictionary] = [
	{"cor": Color.TOMATO, "nome": "Agressivo", "peso": 75.0},
	{"cor": Color.LIME_GREEN, "nome": "Defensivo", "peso": 25.0}
]:
	set(v):
		opcoes_config = v
		queue_redraw()

# Variáveis internas
var indice_selecionado: int = -1 

# --- NOVO: Inicialização da Fonte ---
func _ready() -> void:
	# Garante que existe uma fonte para não dar erro se o usuário não arrastar uma
	if not fonte:
		fonte = SystemFont.new()
		# Configurações básicas para a fonte de sistema ficar mais legível
		(fonte as SystemFont).multichannel_signed_distance_field = true
		(fonte as SystemFont).oversampling = 1.5
	queue_redraw()

func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		rotation += velocidade_rotacao * delta

func _draw() -> void:
	if opcoes_config.is_empty(): return
	
	# Garante que a fonte existe antes de tentar desenhar (segurança para modo editor)
	if not fonte and Engine.is_editor_hint():
		fonte = SystemFont.new()

	var peso_total = 0.0
	for op in opcoes_config: peso_total += op.get("peso", 50.0)
	
	var angulo_atual = -PI / 2
	var raio_linha_fim = raio + (espessura / 2.0)
	var raio_linha_inicio = 0

	if desenhar_linhas:
		var angulo_temp = angulo_atual
		for i in range(opcoes_config.size()):
			var peso = opcoes_config[i].get("peso", 50.0)
			var tamanho_angular = (peso / peso_total) * TAU if peso_total > 0 else 0
			
			var angulo_linha = angulo_temp + tamanho_angular
			var dir = Vector2(cos(angulo_linha), sin(angulo_linha))
			draw_line(dir * raio_linha_inicio, dir * raio_linha_fim, cor_linha, espessura_linha)
			angulo_temp += tamanho_angular

	# Loop de desenho dos Arcos e Texto
	for i in range(opcoes_config.size()):
		var op = opcoes_config[i]
		var peso = op.get("peso", 50.0)
		var tamanho_angular = (peso / peso_total) * TAU if peso_total > 0 else 0
		
		var raio_desenho = raio
		var espessura_desenho = espessura
		var cor = op.get("cor", Color.WHITE)
		
		# --- Destaque ---
		var cor_txt_atual = cor_texto
		if i == indice_selecionado:
			raio_desenho += 5.0
			espessura_desenho += 4.0
			cor = cor.lightened(0.2)
			# Opcional: Mudar cor do texto quando selecionado
			# cor_txt_atual = Color.YELLOW 

		var inicio = angulo_atual + padding
		var fim = angulo_atual + tamanho_angular - padding
		
		draw_arc(Vector2.ZERO, raio_desenho, inicio, fim, suavidade, cor, espessura_desenho, true)
		
		# --- NOVO: DESENHO DO TEXTO ---
		if fonte and tamanho_angular > 0.1: # Só desenha se a fatia for grande o suficiente
			# 1. Calcula o ângulo central desta fatia
			var angulo_centro = angulo_atual + (tamanho_angular / 2.0)
			
			# 2. Calcula a posição onde o texto vai ficar (centro do arco + offset)
			var dir_texto = Vector2(cos(angulo_centro), sin(angulo_centro))
			var pos_texto = dir_texto * (raio + offset_texto)
			
			# 3. Prepara o Texto
			var texto_string = str(op.get("nome", ""))
			# Mede o tamanho do texto para centralizar
			var tamanho_string = fonte.get_string_size(texto_string, HORIZONTAL_ALIGNMENT_CENTER, -1, tamanho_fonte)
			
			# 4. Gira a "Caneta" do Godot para o ângulo certo
			# (+ PI/2 faz o texto ficar "em pé" apontando para fora)
			draw_set_transform(pos_texto, angulo_centro + PI/2, Vector2.ONE)
			
			# 5. Escreve o texto (compensando a posição para ficar centralizado)
			# O ajuste Y/4 é para tentar centralizar verticalmente na linha de base
			draw_string(fonte, Vector2(-tamanho_string.x / 2, tamanho_string.y / 4), texto_string, HORIZONTAL_ALIGNMENT_CENTER, -1, tamanho_fonte, cor_txt_atual)
			
			# 6. Reseta a transformação para não estragar o próximo arco
			draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		# -----------------------------
		
		angulo_atual += tamanho_angular

func aplicar_mudanca_percentual(indice_alvo: int, variacao: float):
	if indice_alvo < 0 or indice_alvo >= opcoes_config.size(): return
	
	# Definimos um mínimo de segurança para NENHUM arco sumir ou inverter
	var minimo = 2.0 
	
	# Calcula o máximo que o alvo pode ter, reservando o espaço mínimo dos outros
	var maximo = 100.0 - (minimo * (opcoes_config.size() - 1))
	
	var peso_atual = opcoes_config[indice_alvo].get("peso", 50.0)
	
	# 1. Calcula e trava o novo peso do ALVO (Isso você já fazia)
	var novo_peso_alvo = clamp(peso_atual + variacao, minimo, maximo)
	var diferenca_real = novo_peso_alvo - peso_atual
	
	if abs(diferenca_real) < 0.01: return
	
	animar_peso(indice_alvo, novo_peso_alvo)
	
	var outros_indices = []
	for i in range(opcoes_config.size()):
		if i != indice_alvo: outros_indices.append(i)
	
	if outros_indices.is_empty(): return
	
	var subtracao_por_irmao = diferenca_real / float(outros_indices.size())
	
	for i in outros_indices:
		var p = opcoes_config[i].get("peso", 50.0)
		var novo_peso_irmao = p - subtracao_por_irmao
		
		if novo_peso_irmao < minimo:
			novo_peso_irmao = minimo
			
		animar_peso(i, novo_peso_irmao)

func animar_peso(indice: int, alvo: float):
	var tween = create_tween()
	var inicial = opcoes_config[indice].get("peso", 50.0)
	
	tween.tween_method(
		func(val): 
			opcoes_config[indice]["peso"] = val
			queue_redraw(),
		inicial,
		alvo,
		1.5
	).set_ease(Tween.EASE_OUT)

func detectar_indice_no_mouse(posicao_global_cursor: Vector2) -> int:
	var pos_local = to_local(posicao_global_cursor)
	if pos_local.length() < 10.0: return -1

	var angulo_toque = atan2(pos_local.y, pos_local.x)
	var angulo_normalizado = fposmod(angulo_toque - (-PI/2), TAU)
	
	var peso_total = 0.0
	for op in opcoes_config: peso_total += op.get("peso", 50.0)
	
	var angulo_percorrido = 0.0
	
	for i in range(opcoes_config.size()):
		var peso = opcoes_config[i].get("peso", 50.0)
		var tamanho_fatia = (peso / peso_total) * TAU
		
		if angulo_normalizado < (angulo_percorrido + tamanho_fatia):
			if i != indice_selecionado:
				indice_selecionado = i
				queue_redraw()
			return i
		angulo_percorrido += tamanho_fatia
	
	if opcoes_config.size() > 0: return opcoes_config.size() - 1
	return -1

func detectar_opcao_no_mouse(posicao_global_cursor: Vector2) -> Dictionary:
	var idx = detectar_indice_no_mouse(posicao_global_cursor)
	if idx != -1: return opcoes_config[idx]
	return {}
