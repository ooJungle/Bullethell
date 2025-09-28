extends Area2D

@export var forca_gravidade: float = 25000.0
@export var wormhole_exit: Node2D

@onready var horizonte_de_eventos: Area2D = $horizonte_de_eventos
var raio_maximo: float

func _ready() -> void:
	add_to_group("buracos_negros")
	horizonte_de_eventos.body_entered.connect(_on_horizonte_de_eventos_body_entered)
	if has_node("campo_gravitacional"):
		raio_maximo = $campo_gravitacional.shape.radius
	else:
		raio_maximo = 0.0

func _physics_process(delta: float) -> void:
	# Agora só afeta corpos que NÃO são jogadores ou inimigos (ex: projéteis)
	var corpos_afetados = get_overlapping_bodies()
	for body in corpos_afetados:
		if body.is_in_group("players") or body.is_in_group("enemies") or body is StaticBody2D:
			continue
		
		var direcao = (global_position - body.global_position).normalized()
		var distancia = global_position.distance_to(body.global_position)
		if distancia < 1.0: continue
		
		var forca = (forca_gravidade / distancia)
		if "velocity" in body:
			body.velocity += direcao * forca * delta * Global.fator_tempo

func _on_horizonte_de_eventos_body_entered(body: Node2D) -> void:
	if not is_instance_valid(wormhole_exit): return
	body.global_position = wormhole_exit.global_position
	if wormhole_exit.has_method("repelir_objeto"):
		wormhole_exit.repelir_objeto(body)
	print(body.name, body.global_position)
