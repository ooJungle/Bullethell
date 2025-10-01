extends Area2D

# --- Variáveis de Configuração ---
@export var forca_gravidade: float = 25000.0
@export var wormhole_exit: Node2D
const PontoDaEspiral = preload("res://Cenas/Projeteis/ponto_espiral.tscn")
const projetil_espiral = preload("res://Cenas/Projeteis/projetil_espiral.tscn")
# --- Variáveis Internas ---
@onready var event_horizon: Area2D = $horizonte_de_eventos
var raio_maximo: float

func _ready() -> void:
	add_to_group("buracos_negros")
	if has_node("campo_gravitacional"):
		raio_maximo = $campo_gravitacional.shape.radius
	else:
		raio_maximo = 0.0


func _physics_process(delta: float) -> void:
	# A gravidade agora só afeta objetos que NÃO são o jogador
	var corpos_afetados = get_overlapping_bodies()
	for body in corpos_afetados:
		if body.is_in_group("players"):
			continue

		if body is StaticBody2D:
			continue
			
		var direcao = (global_position - body.global_position).normalized()
		var distancia = global_position.distance_to(body.global_position)
		if distancia < 1.0: continue
		
		var forca = (forca_gravidade / distancia)
		if "velocity" in body:
			body.velocity += direcao * forca * delta * Global.fator_tempo


# --- LÓGICA DE TELEPORTE ATUALIZADA ---

# Sinal que deteta Corpos (Jogador, Inimigos)
func _on_horizonte_de_eventos_body_entered(body: Node2D) -> void:
	_teleport_object(body)

# Novo sinal que deteta Áreas (Projéteis)
func _on_horizonte_de_eventos_area_entered(area: Area2D) -> void:
	# Para o projétil espiral, queremos teleportar o objeto PAI (o conjunto todo)
	if area.get_parent() is Area2D and area.get_parent().is_in_group("projeteis_espiral"):
		_teleport_object(area.get_parent())
	else:
		_teleport_object(area)

# Nova função genérica que faz o trabalho sujo
func _teleport_object(object: Node2D) -> void:
	if not is_instance_valid(wormhole_exit):
		print("ERRO: Buraco de Minhoca de saída não definido!")
		return
	if object.name == "buraco_negro":
		return
	if object.name.begins_with("ponto"):
		return
	if not is_instance_valid(object):
		return

	object.global_position = wormhole_exit.global_position
	
	if wormhole_exit.has_method("repelir_objeto"):
		wormhole_exit.repelir_objeto(object)
