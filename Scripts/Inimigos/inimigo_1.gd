extends CharacterBody2D

# --- Variáveis de Movimento e Percepção ---
@export var velocidade = 150.0 # Velocidade máxima de movimento.
@export var forca_maxima_direcao = 200.0 # Quão rápido o inimigo pode mudar de direção (aceleração/steering).
@export var tempo_percepcao = 0.5 # A cada quantos segundos o inimigo recalcula o caminho para o jogador.

# --- Variáveis de Combate ---
@export var player: Node2D
@export var forca_knockback = 600.0 # Força do empurrão ao receber knockback.
const obj_tiro_azul = preload("res://Cenas/Projeteis/tiro_azul.tscn")

# --- Nós Filhos (Adicione-os na cena do inimigo!) ---
@onready var sprite: AnimatedSprite2D = $sprite
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var perception_timer: Timer = $PerceptionTimer
# A Area2D é usada para detectar o jogador para o knockback por colisão.
@onready var collision_area: Area2D = $CollisionArea

# --- Variáveis de Estado Interno ---
var shoot_timer = 0.0
var knockback = false
var tempo_knockback_atual = 0.0


func _ready() -> void:
	add_to_group("enemies")
	# Conecta o timer de percepção à função que calcula o caminho.
	perception_timer.wait_time = tempo_percepcao
	perception_timer.timeout.connect(recalcular_caminho)
	
	# Calcula o caminho inicial assim que o inimigo é criado.
	recalcular_caminho()


func _physics_process(delta: float) -> void:
	if Global.paused: # Assumindo que você tem um autoload 'Global' para pausar.
		return
	
	shoot_timer += delta
	# Se o jogador não for válido (ex: foi destruído), o inimigo para.
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# --- LÓGICA DE KNOCKBACK ---
	if knockback:
		tempo_knockback_atual += delta
		# O estado de knockback dura 0.3 segundos.
		if tempo_knockback_atual >= 0.3:
			knockback = false
		
		# Reduz gradualmente a velocidade do knockback até parar.
		velocity = velocity.lerp(Vector2.ZERO, delta * 5.0)
		move_and_slide()
		return # Pula o resto da lógica de movimento enquanto estiver em knockback.

	# --- LÓGICA DE MOVIMENTO COM PATHFINDING ---
	var direcao_alvo = Vector2.ZERO
	if not navigation_agent.is_navigation_finished():
		# Pega a direção para o próximo ponto do caminho calculado pelo NavigationAgent2D.
		direcao_alvo = global_position.direction_to(navigation_agent.get_next_path_position())

	# Se há uma direção para seguir, aplica a força para se mover.
	if direcao_alvo.length() > 0:
		var velocidade_desejada = direcao_alvo * velocidade
		# Calcula a força necessária para mudar da velocidade atual para a desejada.
		var forca_direcao = velocidade_desejada - velocity
		forca_direcao = forca_direcao.limit_length(forca_maxima_direcao)
		
		# Aplica a força de direção para um movimento mais suave.
		velocity += forca_direcao * delta
		velocity = velocity.limit_length(velocidade)
	else:
		# Se chegou ao destino, desacelera suavemente.
		velocity = velocity.lerp(Vector2.ZERO, delta * 3.0)

	move_and_slide()
	
	update_animation_and_flip()
	
	# Dispara se o jogador estiver a uma certa distância.
	if (player.global_position - global_position).length() < 500:
		shoot()


# --- FUNÇÕES DE LÓGICA ---

# Esta função é chamada pelo Timer de Percepção.
func recalcular_caminho() -> void:
	if is_instance_valid(player):
		# Define o alvo do agente de navegação para a posição atual do jogador.
		navigation_agent.target_position = player.global_position

# Função para atirar
func shoot():
	if shoot_timer >= 1.2:
		var new_bullet = obj_tiro_azul.instantiate()
		var direction = (player.global_position - global_position).normalized()
		
		new_bullet.position = global_position
		new_bullet.velocity = direction * velocidade # Ou uma velocidade específica para o projétil
		get_parent().add_child(new_bullet)
		shoot_timer = 0.0

# Aplica o knockback quando colide com o jogador.
func aplicar_knockback(direcao: Vector2):
	knockback = true
	tempo_knockback_atual = 0.0
	velocity = direcao * forca_knockback

# Atualiza a animação e a direção do sprite.
func update_animation_and_flip():
	if velocity.length() > 10:
		sprite.play("Walking")
		if velocity.x > 0: sprite.flip_h = false
		elif velocity.x < 0: sprite.flip_h = true
	else:
		sprite.play("Idle")


# --- CONEXÃO DE SINAIS ---

# Este sinal vem da Area2D que detecta a colisão com o corpo do jogador.
func _on_collision_area_body_entered(body: Node2D) -> void:
	# Ignora colisões se já estiver em knockback ou se colidir consigo mesmo.
	if knockback or body == self:
		return
	
	# Verifica se o corpo que entrou na área pertence ao grupo "players".
	if body.is_in_group("players"):
		var direcao = (global_position - body.global_position).normalized()
		aplicar_knockback(direcao)
