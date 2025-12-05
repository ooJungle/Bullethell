@tool
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

# --- OPÇÕES (Agora baseadas em Porcentagem 0-100) ---
@export_group("Opções")
@export var opcoes_config: Array[Dictionary] = [
	{"cor": Color.TOMATO, "nome": "Agressivo", "peso": 33.33},
	{"cor": Color.YELLOW, "nome": "Neutro", "peso": 33.33},
	{"cor": Color.LIME_GREEN, "nome": "Defensivo", "peso": 33.33}
]:
	set(v):
		opcoes_config = v
		queue_redraw()

# Variáveis internas
var indice_selecionado: int = -1 

func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		rotation += velocidade_rotacao * delta

func _draw() -> void:
	if opcoes_config.is_empty(): return
	
	var peso_total = 0.0
	for op in opcoes_config: peso_total += op.get("peso", 33.3)
	
	var angulo_atual = -PI / 2
	var raio_linha_fim = raio + (espessura / 2.0)
	var raio_linha_inicio = 0

	if desenhar_linhas:
		var angulo_temp = angulo_atual
		for i in range(opcoes_config.size()):
			var peso = opcoes_config[i].get("peso", 33.3)
			var tamanho_angular = (peso / peso_total) * TAU if peso_total > 0 else 0
			
			var angulo_linha = angulo_temp + tamanho_angular
			var dir = Vector2(cos(angulo_linha), sin(angulo_linha))
			draw_line(dir * raio_linha_inicio, dir * raio_linha_fim, cor_linha, espessura_linha)
			angulo_temp += tamanho_angular

	for i in range(opcoes_config.size()):
		var op = opcoes_config[i]
		var peso = op.get("peso", 33.3)
		var tamanho_angular = (peso / peso_total) * TAU if peso_total > 0 else 0
		
		var raio_desenho = raio
		var espessura_desenho = espessura
		var cor = op.get("cor", Color.WHITE)
		
		if i == indice_selecionado:
			raio_desenho += 5.0
			espessura_desenho += 4.0
			cor = cor.lightened(0.2)

		var inicio = angulo_atual + padding
		var fim = angulo_atual + tamanho_angular - padding
		
		draw_arc(Vector2.ZERO, raio_desenho, inicio, fim, suavidade, cor, espessura_desenho, true)
		angulo_atual += tamanho_angular

func aplicar_mudanca_percentual(indice_alvo: int, variacao: float):
	if indice_alvo < 0 or indice_alvo >= opcoes_config.size(): return
	
	var minimo = 2.0
	var maximo = 100.0 - (minimo * (opcoes_config.size() - 1))
	var peso_atual = opcoes_config[indice_alvo].get("peso", 33.3)
	var novo_peso = clamp(peso_atual + variacao, minimo, maximo)
	var diferenca_real = novo_peso - peso_atual
	
	if diferenca_real == 0: return
	
	animar_peso(indice_alvo, novo_peso)
	
	var outros_indices = []
	for i in range(opcoes_config.size()):
		if i != indice_alvo: outros_indices.append(i)
	
	var subtracao_por_irmao = diferenca_real / float(outros_indices.size())
	
	for i in outros_indices:
		var p = opcoes_config[i].get("peso", 33.3)
		animar_peso(i, p - subtracao_por_irmao)

func animar_peso(indice: int, alvo: float):
	var tween = create_tween()
	var inicial = opcoes_config[indice].get("peso", 33.3)
	
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
	for op in opcoes_config: peso_total += op.get("peso", 33.3)
	
	var angulo_percorrido = 0.0
	
	for i in range(opcoes_config.size()):
		var peso = opcoes_config[i].get("peso", 33.3)
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
