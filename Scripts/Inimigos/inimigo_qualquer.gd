extends CharacterBody2D

# --- Variáveis de Movimento e Percepção ---
@export var velocidade = 150.0 
@export var forca_maxima_direcao = 200.0 
@export var tempo_percepcao = 0.5 

# --- Variáveis de Combate ---
@export var player: CharacterBody2D
@export var forca_knockback = 600.0 
@export var tempo_vida_maximo: float = 30.0
@export var velocidade_projetil = 230.0

# --- CONTROLE DE CADÊNCIA (MUDANÇA AQUI) ---
@export var intervalo_entre_tiros: float = 3.0 # Ajuste esse valor no Inspector

const obj_tiro_roxo = preload("res://Cenas/Projeteis/tiro_central.tscn")

# --- Nós Filhos ---
@onready var sprite: AnimatedSprite2D = $sprite
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var perception_timer: Timer = $PerceptionTimer
@onready var collision_area: Area2D = $CollisionArea

# --- Variáveis de Estado Interno ---
var shoot_timer = 0.0
var knockback = false
var tempo_knockback_atual = 0.0
var tempo_vida_atual: float = 0.0

func _ready() -> void:
	add_to_group("inimigo")
	perception_timer.one_shot = true
	# Pequeno atraso aleatório para evitar lag ao nascer
	perception_timer.wait_time = tempo_percepcao + randf_range(-0.3, 0.3)
	perception_timer.timeout.connect(on_perception_timer_timeout)
	perception_timer.start()
	
	player = get_node_or_null("/root/Node2D/player")
	if not player:
		player = get_node_or_null("/root/fase_teste/player")

func on_perception_timer_timeout() -> void:
	if Global.paused or !visible:
		return
	
	# Mantendo sua lógica original de navegação
	if is_instance_valid(player):
		navigation_agent.target_position = player.global_position

	perception_timer.wait_time = tempo_percepcao + randf_range(-0.3, 0.3)
	perception_timer.start()

func _physics_process(delta: float) -> void:
	if Global.paused or !visible:
		return
	
	# Lógica de Tempo de Vida
	tempo_vida_atual += delta * Global.fator_tempo
	if tempo_vida_atual >= tempo_vida_maximo:
		queue_free()
		return

	shoot_timer += delta * Global.fator_tempo
	
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if knockback:
		tempo_knockback_atual += delta
		if tempo_knockback_atual >= 0.3:
			knockback = false
		velocity = velocity.lerp(Vector2.ZERO, delta * 5.0)
		move_and_slide()
		return

	# --- LÓGICA ORIGINAL DE MOVIMENTO (MANTIDA) ---
	var direcao_alvo = Vector2.ZERO
	if not navigation_agent.is_navigation_finished():
		direcao_alvo = global_position.direction_to(navigation_agent.get_next_path_position())

	if direcao_alvo.length() > 0:
		var velocidade_desejada = direcao_alvo * velocidade
		var forca_direcao = velocidade_desejada - velocity
		forca_direcao = forca_direcao.limit_length(forca_maxima_direcao)
		velocity += forca_direcao * delta * Global.fator_tempo
		velocity = velocity.limit_length(velocidade)
	else:
		velocity = velocity.lerp(Vector2.ZERO, delta * 3.0 * Global.fator_tempo)

	move_and_slide()
	
	update_animation_and_flip()
	
	if (player.global_position - global_position).length() < 500:
		shoot()

func shoot():
	# --- MUDANÇA SOMENTE AQUI ---
	# Usa a variável exportada em vez do número fixo 1.2
	if shoot_timer >= intervalo_entre_tiros:
		var new_bullet = obj_tiro_roxo.instantiate()
		new_bullet.position = global_position
		
		# Mantém a lógica de atirar na direção do player
		if is_instance_valid(player):
			var direction = (player.global_position - global_position).normalized()
			if "velocity" in new_bullet:
				new_bullet.velocity = direction * velocidade_projetil
			
		get_parent().add_child(new_bullet)
		shoot_timer = 0.0

func update_animation_and_flip():
	if velocity.length() > 10:
		sprite.play("Walking")
		if velocity.x > 0: sprite.flip_h = false
		elif velocity.x < 0: sprite.flip_h = true
	else:
		sprite.play("Idle")

func aplicar_knockback(direcao: Vector2):
	knockback = true
	tempo_knockback_atual = 0.0
	velocity = direcao * forca_knockback*2

func _on_collision_area_body_entered(body: Node2D) -> void:
	if knockback or body == self:
		return
	if body.is_in_group("player"):
		var direcao = (global_position - body.global_position).normalized()
		aplicar_knockback(direcao)
		body.take_damage(5)

func take_damage(amount: int) -> void:
	queue_free()
