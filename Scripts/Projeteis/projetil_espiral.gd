# Script: projetil_espiral.gd
extends Area2D

# Carregamos a "peça" que vai formar a nossa espiral
const PontoDaEspiral = preload("res://Cenas/Projeteis/Ponto_Espiral.tscn") # Ajuste o caminho!

# A velocidade de todo o conjunto
var velocity: Vector2 = Vector2.ZERO

# --- Variáveis para a Física ---
var buraco_negro_proximo: Node2D = null
var buraco_minhoca_proximo: Node2D = null

func _ready() -> void:
	# Conecta o sinal de colisão DESTE nó (o central) à sua própria função
	# (Adicione uma hitbox ao nó raiz se quiser que o centro também colida)
	# body_entered.connect(_on_body_entered)

	# --- LÓGICA PARA CONSTRUIR A ESPIRAL ---
	var numero_de_pontos = 50
	var separacao_angular = 20.0
	var incremento_raio = 2.0

	for i in range(numero_de_pontos):
		var novo_ponto = PontoDaEspiral.instantiate()

		var angulo = i * separacao_angular
		var raio = i * incremento_raio

		var offset = Vector2.RIGHT.rotated(deg_to_rad(angulo)) * raio

		add_child(novo_ponto)
		novo_ponto.position = offset
		novo_ponto.name = "ponto"
		print(novo_ponto.name)
	await get_tree().create_timer(20.0).timeout
	if is_instance_valid(self):
		queue_free()

func _physics_process(delta: float) -> void:
	# 1. Encontra os corpos celestes mais próximos
	buraco_negro_proximo = encontrar_corpo_celeste_mais_proximo("buracos_negros")
	buraco_minhoca_proximo = encontrar_corpo_celeste_mais_proximo("buracos_minhoca")

	# 2. Calcula e aplica as forças de atração/repulsão
	var forca_externa = calcular_forcas_externas()
	velocity += forca_externa * delta * Global.fator_tempo

	# 3. Move o conjunto inteiro com a velocidade atualizada
	position += velocity * delta * Global.fator_tempo

# --- FUNÇÕES DE FÍSICA PARA O PROJÉTIL ---
func calcular_forcas_externas() -> Vector2:
	var forca_total = Vector2.ZERO
	
	# Força de atração do Buraco Negro
	if is_instance_valid(buraco_negro_proximo):
		var dist = global_position.distance_to(buraco_negro_proximo.global_position)
		if dist > 1.0 and dist < buraco_negro_proximo.raio_maximo:
			var direcao = (buraco_negro_proximo.global_position - global_position).normalized()
			var forca = (buraco_negro_proximo.forca_gravidade / dist) # Fórmula simplificada para projéteis
			forca_total += direcao * forca
			
	# Força de repulsão do Buraco de Minhoca
	if is_instance_valid(buraco_minhoca_proximo):
		var dist = global_position.distance_to(buraco_minhoca_proximo.global_position)
		if dist > 1.0 and dist < buraco_minhoca_proximo.raio_maximo:
			var direcao = (global_position - buraco_minhoca_proximo.global_position).normalized()
			var forca = (buraco_minhoca_proximo.forca_repulsao_campo / dist) # Fórmula simplificada
			forca_total += direcao * forca

	return forca_total


func encontrar_corpo_celeste_mais_proximo(grupo: String) -> Node2D:
	var nos_no_grupo = get_tree().get_nodes_in_group(grupo)
	var mais_proximo = null
	var min_dist = INF
	
	if nos_no_grupo.is_empty():
		return null

	for no in nos_no_grupo:
		var dist = global_position.distance_squared_to(no.global_position)
		if dist < min_dist:
			min_dist = dist
			mais_proximo = no
			
	return mais_proximo

# (Opcional: Adicione esta função se o centro da espiral também puder causar dano)
# func _on_body_entered(body: Node2D):
# 	if body.is_in_group("players"):
# 		if body.has_method("take_damage"):
# 			body.take_damage(1)
	# 	# Destruir ao colidir com o jogador ou paredes
	# 	queue_free()
