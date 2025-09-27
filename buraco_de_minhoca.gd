extends Area2D

# --- Variáveis de Configuração ---
@export var forca_repulsao_saida: float = 10000.0 # A "explosão" inicial após o teleporte
@export var forca_repulsao_campo: float = 25000.0 # A força contínua do campo (igual à do BN)

# --- Variáveis Internas ---
# Adicionada para que o script do jogador possa ler o raio de efeito
var raio_maximo: float

func _ready() -> void:
	# Adiciona-se a si mesmo a um grupo para que o jogador o possa encontrar
	add_to_group("buracos_minhoca")
	
	# Define o raio máximo automaticamente com base no tamanho da sua CollisionShape
	if has_node("campo_repulsao"):
		raio_maximo = $campo_repulsao.shape.radius
	else:
		print("AVISO: Nó CollisionShape2D chamado 'campo_repulsao' não encontrado no Buraco de Minhoca.")
		raio_maximo = 0.0


func _physics_process(delta: float) -> void:
	# O campo de repulsão agora só afeta inimigos e projéteis
	var corpos_afetados = get_overlapping_bodies()
	
	for body in corpos_afetados:
		# Pula o jogador, pois ele calcula a sua própria força
		if body.is_in_group("players"):
			continue

		if body is StaticBody2D:
			continue
			
		# A DIREÇÃO É INVERTIDA: do centro do buraco para o corpo
		var direcao = (body.global_position - global_position).normalized()
		var distancia = global_position.distance_to(body.global_position)
		
		# Usamos a mesma lógica de cálculo de força do Buraco Negro
		if distancia < 1.0:
			continue
		
		var forca = (forca_repulsao_campo / distancia)
		
		if "velocity" in body:
			# Empurra o corpo para longe
			body.velocity += direcao * forca * delta * Global.fator_tempo


# Esta função é chamada pelo Buraco Negro DEPOIS de teleportar um objeto
func repelir_objeto(body: Node2D):
	if "velocity" in body:
		var direcao_aleatoria = Vector2.RIGHT.rotated(randf() * TAU)
		
		if body.is_in_group("players"):
			body.velocity = direcao_aleatoria * forca_repulsao_saida
		else:
			body.velocity = direcao_aleatoria * forca_repulsao_saida * Global.fator_tempo
