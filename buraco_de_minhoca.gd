extends Area2D

# --- Variáveis de Configuração ---
@export var forca_repulsao_saida: float = 100.0 # A "explosão" inicial após o teleporte
@export var forca_repulsao_campo: float = 25000.0 # A força contínua do campo para NPCs

# --- Variáveis Internas ---
# Adicionada para que o jogador e inimigos possam ler o raio de efeito
var raio_maximo: float

func _ready() -> void:
	# Adiciona-se a si mesmo a um grupo para que outros nós o possam encontrar
	add_to_group("buracos_minhoca")
	
	# Define o raio máximo automaticamente com base no tamanho da sua CollisionShape
	# Certifique-se de que o seu CollisionShape2D se chama "RepulsionField"
	if has_node("campo_repulsao"):
		raio_maximo = $campo_repulsao.shape.radius
	else:
		print("AVISO: Nó CollisionShape2D chamado 'campo_repulsao' não encontrado no Buraco de Minhoca.")
		raio_maximo = 0.0


func _physics_process(delta: float) -> void:
	# O campo de repulsão agora só afeta objetos que não são o jogador ou inimigos (ex: projéteis)
	var corpos_afetados = get_overlapping_bodies()
	
	for body in corpos_afetados:
		# Pula o jogador e os inimigos, pois eles calculam a sua própria força
		if body.is_in_group("players") or body.is_in_group("enemies"):
			continue

		if body is StaticBody2D:
			continue
			
		var direcao = (body.global_position - global_position).normalized()
		var distancia = global_position.distance_to(body.global_position)
		
		if distancia < 1.0:
			continue
		
		# Usamos uma fórmula simples de 1/dist para a força
		var forca = (forca_repulsao_campo / distancia)
		
		if "velocity" in body:
			# Empurra o corpo para longe, afetado pelo tempo global
			body.velocity += direcao * forca * delta * Global.fator_tempo


# Esta função é chamada pelo Buraco Negro DEPOIS de teleportar um objeto
func repelir_objeto(body: Node2D):
	if "velocity" in body:
		var direcao_aleatoria = Vector2.RIGHT.rotated(randf() * TAU)
		
		# A velocidade do jogador NÃO é afetada pelo tempo global, pois o seu script já o faz
		if body.is_in_group("players"):
			body.velocity = direcao_aleatoria * forca_repulsao_saida
		else:
			# Outros objetos são afetados pelo tempo global
			body.velocity = direcao_aleatoria * forca_repulsao_saida * Global.fator_tempo
