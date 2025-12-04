extends Node2D

@export var bala_cena_vermelho: PackedScene
@export var bala_cena_rosa: PackedScene
@export var bala_cena_amarelo: PackedScene
@export var bala_cena_azul: PackedScene

@export var velocidade_giro: float = 2.0
@export var intervalo_tiro: float = 0.1
@export var raio_da_roda: float = 150.0 # Tamanho da arena para calcular bordas

# --- NOVOS PADRÕES ---
enum Padrao { CENTRO, BORDA_PRA_DENTRO, ORBITA, ALEATORIO }
@export var padrao_atual: Padrao = Padrao.CENTRO

var tempo_tiro = 0.0

func _process(delta: float):
	rotation += velocidade_giro * delta

	tempo_tiro -= delta
	if tempo_tiro <= 0:
		atirar()
		tempo_tiro = intervalo_tiro

func _on_timer_troca_padrao_timeout():
	padrao_atual = Padrao.values().pick_random()

func atirar():
	if not bala_cena_vermelho: return
	
	# 1. Escolhe a bala (Sua lógica original)
	var bala
	var sorteio = randi_range(1,4)
	if sorteio == 1: bala = bala_cena_vermelho.instantiate()
	elif sorteio == 2: bala = bala_cena_amarelo.instantiate()
	elif sorteio == 3: bala = bala_cena_rosa.instantiate()
	else: bala = bala_cena_azul.instantiate()	
		
	# 2. Adiciona ao Container (Máscara)
	var conteiner = get_node_or_null("../ConteinerTiros")
	if conteiner:
		conteiner.add_child(bala)
	else:
		get_parent().add_child(bala)
	
	bala.top_level = false 
	
	# --- 3. LÓGICA DE POSIÇÃO E DIREÇÃO VARIÁVEL ---
	
	var posicao_nascimento = Vector2.ZERO
	var direcao_tiro = Vector2.RIGHT
	
	match padrao_atual:
		Padrao.CENTRO:
			# O Clássico: Sai do meio e vai para fora girando
			posicao_nascimento = position # (0,0)
			direcao_tiro = Vector2.RIGHT.rotated(rotation)
			
		Padrao.BORDA_PRA_DENTRO:
			# Nasce na borda do círculo e atira para o centro
			# Usamos a rotação atual para definir ONDE na borda ele nasce
			var offset_borda = Vector2.RIGHT.rotated(rotation) * (raio_da_roda - 10)
			posicao_nascimento = position + offset_borda
			
			# A direção é o oposto do offset (para o centro)
			direcao_tiro = -offset_borda.normalized()
			
		Padrao.ORBITA:
			# Nasce um pouco afastado do centro (cria um "olho do furacão" seguro)
			var distancia_centro = 40.0 
			var offset = Vector2.RIGHT.rotated(rotation) * distancia_centro
			posicao_nascimento = position + offset
			direcao_tiro = Vector2.RIGHT.rotated(rotation)
			
		Padrao.ALEATORIO:
			# Nasce em qualquer lugar dentro da roda
			var angulo_rand = randf() * TAU
			var dist_rand = randf_range(0, raio_da_roda - 10)
			posicao_nascimento = Vector2(cos(angulo_rand), sin(angulo_rand)) * dist_rand
			
			# Direção aleatória ou seguindo o fluxo? Vamos fazer aleatória:
			direcao_tiro = Vector2.RIGHT.rotated(randf() * TAU)

	# --- 4. APLICAÇÃO ---
	
	bala.position = posicao_nascimento
	
	if "velocity" in bala:
		bala.velocity = direcao_tiro * 150.0 
	
	bala.rotation = direcao_tiro.angle()
