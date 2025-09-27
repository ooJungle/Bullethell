extends Area2D

# --- Variáveis de Configuração ---
@export var forca_gravidade: float = 25000.0 # Quão forte é a atração para OUTROS objetos
@export var wormhole_exit: Node2D # No Inspector, arraste a sua cena BuracoMinhoca para cá

# --- Variáveis Internas ---
@onready var horizonte_de_eventos: Area2D = $horizonte_de_eventos
# A nova variável que estava em falta. Será definida automaticamente.
var raio_maximo: float

func _ready() -> void:
	# Adiciona-se ao grupo para que o jogador o possa encontrar
	add_to_group("buracos_negros")
	
	# Conecta o sinal da área de teleporte à função de teleporte
	horizonte_de_eventos.body_entered.connect(_on_horizonte_de_eventos_body_entered)
	
	# Define o raio máximo automaticamente com base no tamanho da sua CollisionShape
	# Certifique-se de que o seu CollisionShape2D principal se chama "GravityWell"
	if has_node("campo_gravitacional"):
		raio_maximo = $campo_gravitacional.shape.radius
	else:
		print("AVISO: Nó CollisionShape2D chamado 'GravityWell' não encontrado no Buraco Negro.")
		raio_maximo = 0.0


func _physics_process(delta: float) -> void:
	# A gravidade do Buraco Negro agora só afeta inimigos e projéteis
	var corpos_afetados = get_overlapping_bodies()
	
	for body in corpos_afetados:
		# --- LÓGICA ATUALIZADA ---
		# Pula o jogador, pois ele agora calcula a sua própria gravidade para evitar força dupla
		if body.is_in_group("players"):
			continue

		if body is StaticBody2D:
			continue
			
		var direcao = (global_position - body.global_position).normalized()
		var distancia = global_position.distance_to(body.global_position) + 400
		
		if distancia < 100.0:
			distancia = 100
		
		var forca = (forca_gravidade / (distancia))
		
		if "velocity" in body:
			body.velocity += direcao * forca * delta * Global.fator_tempo 


# Função para teleportar o corpo
func _on_horizonte_de_eventos_body_entered(body: Node2D) -> void:
	if not is_instance_valid(wormhole_exit):
		print("ERRO: Buraco de Minhoca de saída não definido!")
		return
	
	body.global_position = wormhole_exit.global_position
	
	if wormhole_exit.has_method("repelir_objeto"):
		wormhole_exit.repelir_objeto(body)
