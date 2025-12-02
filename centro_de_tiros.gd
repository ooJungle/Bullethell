extends Node2D

@export var bala_cena: PackedScene # Arraste um dos seus projéteis aqui (ex: tiro_roxo.tscn)
@export var velocidade_giro: float = 2.0
@export var intervalo_tiro: float = 0.1

var tempo_tiro = 0.0

func _process(delta: float):
	# 1. Gira o spawner constantemente
	rotation += velocidade_giro * delta
	
	# 2. Atira periodicamente
	tempo_tiro -= delta
	if tempo_tiro <= 0:
		atirar()
		tempo_tiro = intervalo_tiro

func atirar():
	if not bala_cena: return
	
	var bala = bala_cena.instantiate()
	# A bala nasce na posição do centro
	bala.global_position = global_position
	
	# A direção é "para frente" baseado na rotação atual deste nó
	var direcao = Vector2.RIGHT.rotated(rotation)
	
	# Configura a velocidade da bala (assumindo que seu script de bala tenha 'velocity')
	if "velocity" in bala:
		bala.velocity = direcao * 150.0
		
	get_parent().add_child(bala) # Adiciona na Roda, não dentro do spawner que gira
