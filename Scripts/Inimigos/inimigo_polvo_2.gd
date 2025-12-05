extends CharacterBody2D

# --- Variáveis de Movimento e Percepção ---
@export var velocidade = 90.0
@export var tempo_percepcao = 0.5
var timer: float = 0.0

# --- Variáveis de Combate ---
@export var player: CharacterBody2D
@export var forca_knockback = 600.0
@export var velocidade_projetil = 130.0

# --- Preloads dos Projéteis ---
const obj_tiro_roxo = preload("res://Cenas/Projeteis/tiro_polvo.tscn")
const obj_tiro_azul = preload("res://Cenas/Projeteis/tiro_polvo.tscn")
const obj_tiro_verde = preload("res://Cenas/Projeteis/tiro_polvo.tscn")

# --- Nós Filhos ---
@onready var sprite: AnimatedSprite2D = $sprite
# Nota: O NavigationAgent2D não é mais necessário, mas mantive a referência caso precise deletar da cena depois
@onready var collision_area: Area2D = $Area2D

# --- Variáveis de Estado de Ataque ---
var ataque_aleatorio = 0
var attack_cooldown = 0.0
var tempo_entre_tiros = 0.0
var limite_projeteis = 0
var rotacao_ataque = 200.0
var atirando = false
var direcao_ataque_fixa: Vector2 = Vector2.ZERO

# --- Variáveis de Estado de Knockback ---
var knockback = false
var tempo_knockback_atual = 0.0

func _ready() -> void:
	add_to_group("enemies")
	randomize()
	ataque_aleatorio = randi_range(0, 4)
	
	# Busca segura pelo player
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	timer += delta
	if timer >= 15:
		take_damage(1)
	if Global.paused or !visible:
		return
	
	attack_cooldown += delta * Global.fator_tempo
	tempo_entre_tiros += delta * Global.fator_tempo
	
	# Verifica se o player existe antes de tentar se mover
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Lógica de Knockback (Prioridade sobre movimento)
	if knockback:
		tempo_knockback_atual += delta
		if tempo_knockback_atual >= 0.3:
			knockback = false
		velocity = velocity.lerp(Vector2.ZERO, delta * 5.0)
		move_and_slide()
		return

	# --- MOVIMENTAÇÃO SIMPLIFICADA ---
	# Só se move se NÃO estiver atirando (para não atrapalhar o padrão de tiro)
	if not atirando:
		# Calcula a direção direta para o player
		var direcao = (player.global_position - global_position).normalized()
		
		# Aplica a velocidade na direção
		velocity = direcao * velocidade * Global.fator_tempo
	else:
		# Se estiver atirando, para suavemente
		velocity = velocity.lerp(Vector2.ZERO, delta * 3.0 * Global.fator_tempo)

	move_and_slide()
	
	# Lógica de disparo baseada na distância
	if (player.global_position - global_position).length() < 500:
		shoot()

# --- FUNÇÃO HELPER DE TIRO ---
func spawn_bullet(scene: PackedScene, direction: Vector2, speed: float):
	var new_bullet = scene.instantiate()
	new_bullet.global_position = global_position
	
	# Define a velocidade se o script da bala tiver essa variável
	if "velocity" in new_bullet:
		new_bullet.velocity = direction * speed
	
	# Adiciona à cena principal para não herdar movimento do inimigo
	get_tree().current_scene.add_child(new_bullet)
	
	# Evita que o inimigo colida com a própria bala ao nascer
	add_collision_exception_with(new_bullet)

func shoot():
	# ATAQUE 0: Metralhadora giratória
	if ataque_aleatorio == 0:
		if not atirando:
			direcao_ataque_fixa = (player.global_position - global_position).normalized()
		if attack_cooldown >= 3:
			atirando = true
			if tempo_entre_tiros > 0.05:
				rotacao_ataque += 0.1
				var dir_rotacionada = direcao_ataque_fixa.rotated(rotacao_ataque)
				spawn_bullet(obj_tiro_roxo, dir_rotacionada, velocidade_projetil)
				
				limite_projeteis += 1
				tempo_entre_tiros = 0.0
			if limite_projeteis > 30:
				reset_attack_state()

	# ATAQUE 1: Explosão em círculo
	elif ataque_aleatorio == 1:
		if attack_cooldown >= 3:
			for i in range(11):
				var direction = (player.global_position - global_position).normalized().rotated(deg_to_rad(360.0 / 11.0 * i))
				spawn_bullet(obj_tiro_roxo, direction, velocidade_projetil)
			reset_attack_state()

	# ATAQUE 2: Tiro único simples
	elif ataque_aleatorio == 2:
		if attack_cooldown >= 3:
			var direction = (player.global_position - global_position).normalized()
			spawn_bullet(obj_tiro_roxo, direction, velocidade_projetil)
			reset_attack_state()

	# ATAQUE 3: Tiro Azul
	elif ataque_aleatorio == 3:
		if attack_cooldown >= 3:
			var direction = (player.global_position - global_position).normalized()
			spawn_bullet(obj_tiro_azul, direction, velocidade_projetil)
			reset_attack_state()

	# ATAQUE 4: Tiro Verde Múltiplo
	elif ataque_aleatorio == 4:
		if attack_cooldown >= 3:
			for i in range(4):
				var direction = (player.global_position - global_position).normalized()
				spawn_bullet(obj_tiro_verde, direction, velocidade_projetil)
			reset_attack_state()

func reset_attack_state():
	attack_cooldown = 0.0
	limite_projeteis = 0
	rotacao_ataque = 200.0
	atirando = false
	ataque_aleatorio = randi_range(0, 4)

func aplicar_knockback(direcao: Vector2):
	knockback = true
	tempo_knockback_atual = 0.0
	velocity = direcao * forca_knockback * 0.6

func _on_collision_area_body_entered(body: Node2D) -> void:
	if knockback or body == self:
		return
	if body.is_in_group("player"):
		var direcao = (global_position - body.global_position).normalized()
		aplicar_knockback(direcao)
		if body.has_method("take_damage"):
			body.take_damage(5)

func take_damage(_amount: int) -> void:
	Global.inimigo_morreu.emit()
	queue_free()
