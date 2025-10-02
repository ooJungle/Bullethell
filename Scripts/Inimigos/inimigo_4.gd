extends CharacterBody2D

# --- Variáveis de Movimento e Percepção ---
@export var velocidade = 90.0
@export var forca_maxima_direcao = 180.0 # Quão rápido o inimigo pode virar.
@export var tempo_percepcao = 0.5 # A cada quantos segundos o inimigo recalcula o caminho.

# --- Variáveis de Combate ---
@export var player: Node2D
@export var forca_knockback = 600.0
@export var velocidade_projetil = 130.0

# --- Preloads dos Projéteis ---
const obj_tiro_roxo = preload("res://Cenas/Projeteis/tiro_roxo.tscn")
const obj_tiro_azul = preload("res://Cenas/Projeteis/tiro_azul.tscn")
const obj_tiro_verde = preload("res://Cenas/Projeteis/tiro_verde.tscn")

# --- Nós Filhos ---
@onready var sprite: AnimatedSprite2D = $sprite
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var perception_timer: Timer = $PerceptionTimer
@onready var collision_area: Area2D = $CollisionArea

# --- Variáveis de Estado de Ataque ---
var ataque_aleatorio = 0
var attack_cooldown = 0.0 # Renomeei 'timer' para evitar confusão.
var tempo_entre_tiros = 0.0
var limite_projeteis = 0
var rotacao_ataque = 200.0 # Usei float para mais precisão
var atirando = false
var direcao_ataque_fixa: Vector2 = Vector2.ZERO

# --- Variáveis de Estado de Knockback ---
var knockback = false
var tempo_knockback_atual = 0.0


func _ready() -> void:
	randomize() # Inicia a semente de aleatoriedade
	ataque_aleatorio = randi_range(0, 4)
	
	add_to_group("enemies")
	
	# Configura e conecta o timer de percepção para o pathfinding
	perception_timer.wait_time = tempo_percepcao
	perception_timer.timeout.connect(recalcular_caminho)
	
	recalcular_caminho() # Calcula o caminho inicial


func _physics_process(delta: float) -> void:
	if Global.paused:
		return
	
	# Incrementa os timers de ataque
	attack_cooldown += delta
	tempo_entre_tiros += delta
	
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# --- LÓGICA DE KNOCKBACK ---
	if knockback:
		tempo_knockback_atual += delta
		if tempo_knockback_atual >= 0.3:
			knockback = false
		velocity = velocity.lerp(Vector2.ZERO, delta * 5.0)
		move_and_slide()
		return

	# --- LÓGICA DE MOVIMENTO COM PATHFINDING ---
	var direcao_alvo = Vector2.ZERO
	if not atirando: # O inimigo para de se mover enquanto está no meio de um ataque
		if not navigation_agent.is_navigation_finished():
			direcao_alvo = global_position.direction_to(navigation_agent.get_next_path_position())

	if direcao_alvo.length() > 0:
		var velocidade_desejada = direcao_alvo * velocidade
		var forca_direcao = velocidade_desejada - velocity
		forca_direcao = forca_direcao.limit_length(forca_maxima_direcao)
		velocity += forca_direcao * delta
		velocity = velocity.limit_length(velocidade)
	else:
		velocity = velocity.lerp(Vector2.ZERO, delta * 3.0)

	move_and_slide()
	update_animation_and_flip()
	
	# Se o jogador estiver perto, tenta atirar.
	if (player.global_position - global_position).length() < 500:
		shoot()


# --- FUNÇÕES DE LÓGICA ---

func shoot():
	# --- ATAQUE 0: Espiral de tiros ---
	if ataque_aleatorio == 0:
		if not atirando:
			# Trava a direção do jogador no início do ataque
			direcao_ataque_fixa = (player.global_position - global_position).normalized()
		
		if attack_cooldown >= 1.2:
			atirando = true
			if tempo_entre_tiros > 0.01:
				rotacao_ataque += 0.1
				var new_bullet = obj_tiro_roxo.instantiate()
				new_bullet.global_position = global_position
				new_bullet.velocity = (direcao_ataque_fixa * velocidade_projetil).rotated(rotacao_ataque)
				get_parent().add_child(new_bullet)
				limite_projeteis += 1
				tempo_entre_tiros = 0.0
			
			if limite_projeteis > 30:
				# Reseta o estado do ataque e sorteia o próximo
				attack_cooldown = 0.0
				limite_projeteis = 0
				rotacao_ataque = 200.0
				atirando = false
				ataque_aleatorio = randi_range(0, 4)

	# --- ATAQUE 1: Círculo de tiros ---
	if ataque_aleatorio == 1:
		if attack_cooldown >= 1.2:
			for i in range(11):
				var new_bullet = obj_tiro_roxo.instantiate()
				var direction = (player.global_position - global_position).normalized().rotated(deg_to_rad(360.0 / 11.0 * i))
				new_bullet.global_position = global_position
				new_bullet.velocity = direction * velocidade_projetil
				get_parent().add_child(new_bullet)
			# Reseta e sorteia o próximo
			attack_cooldown = 0.0
			ataque_aleatorio = randi_range(0, 4)

	# --- ATAQUE 2: Tiro simples ---
	if ataque_aleatorio == 2:
		if attack_cooldown >= 1.2:
			var new_bullet = obj_tiro_roxo.instantiate()
			var direction = (player.global_position - global_position).normalized()
			new_bullet.global_position = global_position
			new_bullet.velocity = direction * velocidade_projetil
			get_parent().add_child(new_bullet)
			# Reseta e sorteia o próximo
			attack_cooldown = 0.0
			ataque_aleatorio = randi_range(0, 4)

	# --- ATAQUE 3: Tiro teleguiado (azul) ---
	if ataque_aleatorio == 3:
		if attack_cooldown >= 1.2:
			var new_bullet = obj_tiro_azul.instantiate()
			var direction = (player.global_position - global_position).normalized()
			new_bullet.player = player # Passa a referência do jogador para o projétil
			new_bullet.global_position = global_position
			new_bullet.velocity = direction * velocidade_projetil
			get_parent().add_child(new_bullet)
			# Reseta e sorteia o próximo
			attack_cooldown = 0.0
			ataque_aleatorio = randi_range(0, 4)

	# --- ATAQUE 4: Múltiplos tiros (verde) ---
	if ataque_aleatorio == 4:
		if attack_cooldown >= 1.2:
			for i in range(4):
				var new_bullet = obj_tiro_verde.instantiate()
				var direction = (player.global_position - global_position).normalized()
				new_bullet.player = player
				# NOTA: A linha original 'position * i' criaria projéteis muito longe.
				# Mudei para todos saírem da posição do inimigo.
				new_bullet.global_position = global_position 
				new_bullet.velocity = direction * velocidade_projetil
				get_parent().add_child(new_bullet)
			# Reseta e sorteia o próximo
			attack_cooldown = 0.0
			ataque_aleatorio = randi_range(0, 4)


func recalcular_caminho() -> void:
	if is_instance_valid(player) and not atirando:
		navigation_agent.target_position = player.global_position

func aplicar_knockback(direcao: Vector2):
	knockback = true
	tempo_knockback_atual = 0.0
	velocity = direcao * forca_knockback

func update_animation_and_flip():
	if velocity.length() > 10:
		sprite.play("Walking")
		if velocity.x > 0: sprite.flip_h = false
		elif velocity.x < 0: sprite.flip_h = true
	else:
		sprite.play("Idle")


# --- CONEXÃO DE SINAIS ---
func _on_collision_area_body_entered(body: Node2D) -> void:
	if knockback or body == self:
		return
	if body.is_in_group("players"):
		var direcao = (global_position - body.global_position).normalized()
		aplicar_knockback(direcao)
