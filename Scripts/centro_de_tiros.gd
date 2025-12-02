extends Node2D

@export var bala_cena_vermelho: PackedScene
@export var bala_cena_rosa: PackedScene
@export var bala_cena_amarelo: PackedScene
@export var bala_cena_azul: PackedScene

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
	if not bala_cena_vermelho: return
	
	var bala = bala_cena_vermelho.instantiate()
	
	get_parent().add_child(bala)
	bala.top_level = true 
	bala.global_position = global_position
	var direcao = Vector2.RIGHT.rotated(rotation)
	
	if "velocity" in bala:
		bala.velocity = direcao * 150.0
	
	bala.rotation = direcao.angle()
		
	get_parent().add_child(bala)
