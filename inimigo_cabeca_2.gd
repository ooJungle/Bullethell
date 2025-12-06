extends CharacterBody2D

# --- Variáveis de Movimento ---
@export var velocidade = 90.0
# Removemos "forca_maxima_direcao" e "tempo_percepcao" pois não usaremos mais

# --- Variáveis de Combate ---
@export var player: CharacterBody2D
@export var forca_knockback = 600.0
@export var velocidade_projetil = 130.0
const obj_tiro_cabeca = preload("uid://c1jmoiulli385")

# --- Nós Filhos ---
@onready var sprite: AnimatedSprite2D = $sprite
# Removemos NavigationAgent e PerceptionTimer aqui
@onready var collision_area: Area2D = $CollisionArea

# --- Variáveis de Estado ---
var attack_cooldown = 0.0
var knockback = false
var tempo_knockback_atual = 0.0
var timer: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	
	player = get_tree().get_first_node_in_group("players")


func _physics_process(delta: float) -> void:
	timer += delta
	if timer >= 25:
		take_damage(1)
		
	if Global.paused or !visible:
		return
		
	attack_cooldown += delta

	# Se não tiver player, fica parado
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Olha para o player e ajusta sprite
	look_at(player.global_position)
	rotation_degrees -= 90

	# --- LÓGICA DE KNOCKBACK ---
	if knockback:
		tempo_knockback_atual += delta
		if tempo_knockback_atual >= 0.3:
			knockback = false
		velocity = velocity.lerp(Vector2.ZERO, delta * 5.0)
		move_and_slide()
		return

	# --- LÓGICA DE MOVIMENTO SIMPLIFICADA (A que você pediu) ---
	var direcao = Vector2.ZERO
	
	# Eixo X
	if global_position.x < player.global_position.x - 5.0:
		direcao.x = 1 # Vai para a direita
	elif global_position.x > player.global_position.x + 5.0:
		direcao.x = -1 # Vai para a esquerda
		
	# Eixo Y
	if global_position.y < player.global_position.y - 5.0:
		direcao.y = 1 # Vai para baixo
	elif global_position.y > player.global_position.y + 5.0:
		direcao.y = -1 # Vai para cima
	
	# Normaliza para ele não correr mais rápido na diagonal (Matemática básica de vetores)
	if direcao != Vector2.ZERO:
		direcao = direcao.normalized()
	
	velocity = direcao * velocidade
	move_and_slide()
	# -----------------------------------------------------------

	# Tiro
	if (player.global_position - global_position).length() < 500:
		shoot()

func shoot():
	sprite.play("tiro")
	if attack_cooldown >= 3.0:
		for i in range(-1, 2):
			var new_bullet = obj_tiro_cabeca.instantiate()
			new_bullet.global_position = global_position
			
			var base_direction = Vector2.DOWN
			if is_instance_valid(player):
				base_direction = (player.global_position - global_position).normalized()
			var angle_offset = deg_to_rad(i * 5)
			var final_direction = base_direction.rotated(angle_offset)
			new_bullet.velocity = final_direction * velocidade_projetil
			get_parent().add_child(new_bullet)
		attack_cooldown = 0.0

func aplicar_knockback(direcao: Vector2):
	knockback = true
	tempo_knockback_atual = 0.0
	velocity = direcao * forca_knockback*2/3

func _on_collision_area_body_entered(body: Node2D) -> void:
	if knockback or body == self:
		return
	if body.is_in_group("player"):
		var direcao = (global_position - body.global_position).normalized()
		aplicar_knockback(direcao)
		body.take_damage(5)

func take_damage(_amount: int) -> void:	
	Global.inimigo_morreu.emit()
	queue_free()
