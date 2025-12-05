extends Node2D

@export var bala_cena_vermelho: PackedScene
@export var bala_cena_rosa: PackedScene
@export var bala_cena_amarelo: PackedScene
@export var bala_cena_azul: PackedScene

@export var velocidade_giro: float = 2.0
@export var intervalo_tiro: float = 0.1
@export var raio_da_roda: float = 150.0 

# --- NOVOS PADRÕES ---
enum Padrao { CENTRO, BORDA_PRA_DENTRO, ORBITA, ALEATORIO }
@export var padrao_atual: Padrao = Padrao.CENTRO

var tempo_tiro = 0.0

# --- NOVO: Configuração Automática do Timer ---
func _ready() -> void:
	# Cria um novo Timer via código
	var timer_troca = Timer.new()
	timer_troca.wait_time = 5.0 # 5 Segundos
	timer_troca.autostart = true # Começa sozinho
	timer_troca.one_shot = false # Repete para sempre
	
	# Conecta o "timeout" (fim do tempo) à sua função de trocar
	timer_troca.timeout.connect(_on_timer_troca_padrao_timeout)
	
	# Adiciona o timer na cena para ele funcionar
	add_child(timer_troca)

func _process(delta: float):
	rotation += velocidade_giro * delta

	tempo_tiro -= delta
	if tempo_tiro <= 0:
		atirar()
		tempo_tiro = intervalo_tiro

# Esta função agora será chamada automaticamente a cada 5 segundos
func _on_timer_troca_padrao_timeout():
	padrao_atual = Padrao.values().pick_random()
	# print("Padrão alterado para: ", padrao_atual) # Descomente para ver no console

func atirar():
	if not bala_cena_vermelho: return
	
	# 1. Escolhe a bala
	var bala
	var sorteio = randi_range(0,16)
	if sorteio < 5: bala = bala_cena_vermelho.instantiate()
	if 4 < sorteio and sorteio < 10: bala = bala_cena_amarelo.instantiate()
	if 9 < sorteio and sorteio  < 15: bala = bala_cena_rosa.instantiate()
	if 14 < sorteio: bala = bala_cena_azul.instantiate()	
		
	# 2. Adiciona ao Container
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
			posicao_nascimento = position 
			direcao_tiro = Vector2.RIGHT.rotated(rotation)
			
		Padrao.BORDA_PRA_DENTRO:
			var offset_borda = Vector2.RIGHT.rotated(rotation) * (raio_da_roda - 10)
			posicao_nascimento = position + offset_borda
			direcao_tiro = -offset_borda.normalized()
			
		Padrao.ORBITA:
			var distancia_centro = 40.0 
			var offset = Vector2.RIGHT.rotated(rotation) * distancia_centro
			posicao_nascimento = position + offset
			direcao_tiro = Vector2.RIGHT.rotated(rotation)
			
		Padrao.ALEATORIO:
			var angulo_rand = randf() * TAU
			var dist_rand = randf_range(0, raio_da_roda - 10)
			posicao_nascimento = Vector2(cos(angulo_rand), sin(angulo_rand)) * dist_rand
			direcao_tiro = Vector2.RIGHT.rotated(randf() * TAU)

	# --- 4. APLICAÇÃO ---
	
	bala.position = posicao_nascimento
	
	if "velocity" in bala:
		bala.velocity = direcao_tiro * 150.0 
	
	bala.rotation = direcao_tiro.angle()
