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
# O nome no editor é "sprite", então $sprite está correto
@onready var sprite: AnimatedSprite2D = $sprite
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
	
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	timer += delta
	if timer >= 25:
		take_damage(1)
	if Global.paused or !visible:
		return
	
	attack_cooldown += delta * Global.fator_tempo
	tempo_entre_tiros += delta * Global.fator_tempo
	
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Lógica de Knockback
	if knockback:
		tempo_knockback_atual += delta
		if tempo_knockback_atual >= 0.3:
			knockback = false
		velocity = velocity.lerp(Vector2.ZERO, delta * 5.0)
		move_and_slide()
		return

	# --- MOVIMENTAÇÃO SIMPLIFICADA ---
	if not atirando:
		var direcao = (player.global_position - global_position).normalized()
		velocity = direcao * velocidade * Global.fator_tempo
	else:
		velocity = velocity.lerp(Vector2.ZERO, delta * 3.0 * Global.fator_tempo)

	move_and_slide()
	
	# --- SISTEMA DE ANIMAÇÃO ---
	if atirando:
		# Se estiver atirando, força a animação de tiro
		if sprite.animation != "atirando":
			sprite.play("atirando")
	else:
		# Se não estiver atirando e estiver se movendo, toca andando
		if velocity.length() > 5.0:
			if sprite.animation != "andando":
				sprite.play("andando")
			
			# Espelha o sprite baseado na direção horizontal
			if velocity.x < 0:
				sprite.flip_h = true
			elif velocity.x > 0:
				sprite.flip_h = false
		else:
			# Opcional: Se estiver parado e não atirando, pode manter o "andando" pausado ou tocar um idle
			pass
	# --------------------------
	
	if (player.global_position - global_position).length() < 500:
		shoot()

func spawn_bullet(scene: PackedScene, direction: Vector2, speed: float):
	var new_bullet = scene.instantiate()
	new_bullet.global_position = global_position
	
	if "velocity" in new_bullet:
		new_bullet.velocity = direction * speed
	
	get_tree().current_scene.add_child(new_bullet)
	add_collision_exception_with(new_bullet)

func shoot():
	# --- GATILHO VISUAL ---
	# Força a animação "atirando" no momento exato que o cooldown permite o disparo
	if attack_cooldown >= 3:
		sprite.play("atirando")
	# ----------------------

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

	elif ataque_aleatorio == 1:
		if attack_cooldown >= 3:
			for i in range(11):
				var direction = (player.global_position - global_position).normalized().rotated(deg_to_rad(360.0 / 11.0 * i))
				spawn_bullet(obj_tiro_roxo, direction, velocidade_projetil)
			reset_attack_state()

	elif ataque_aleatorio == 2:
		if attack_cooldown >= 3:
			var direction = (player.global_position - global_position).normalized()
			spawn_bullet(obj_tiro_roxo, direction, velocidade_projetil)
			reset_attack_state()

	elif ataque_aleatorio == 3:
		if attack_cooldown >= 3:
			var direction = (player.global_position - global_position).normalized()
			spawn_bullet(obj_tiro_azul, direction, velocidade_projetil)
			reset_attack_state()

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
	
	# Retorna para a animação de andar assim que o ataque acaba
	sprite.play("andando")

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

func take_damage(_amount: int) -> void:
	Global.inimigo_morreu.emit()
	queue_free()
