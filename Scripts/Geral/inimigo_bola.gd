extends CharacterBody2D

# --- Variáveis de Movimento e Combate ---
@export var velocidade = 80.0 # Velocidade MÁXIMA BASE
@export var player: CharacterBody2D
@export var forca_maxima_direcao = 200.0 # Aceleração/Curva
@export var forca_knockback = 450.0

# --- Nós Filhos ---
@onready var sprite: AnimatedSprite2D = $sprite
# NavigationAgent e Timer removidos daqui
@onready var area_deteccao: Area2D = $Area2D

# --- Disparos ---
const obj_tiro_azul = preload("res://Cenas/Projeteis/projetil_espiral.tscn")
var timer = 0.0

var knockback = false
var tempo_knockback = 0.0

func _ready() -> void:
	add_to_group("enemies")
	
	# Lógica do timer de navegação removida
	
	player = get_node_or_null("/root/Node2D/player")
	if not player:
		player = get_node_or_null("/root/fase_teste/player")

func _physics_process(delta: float) -> void:
	if Global.paused or !visible:
		return
	
	timer += delta * Global.fator_tempo
	
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if knockback:
		tempo_knockback += delta
		if tempo_knockback >= 0.4:
			knockback = false
		velocity = velocity.lerp(Vector2.ZERO, delta * 5.0 * Global.fator_tempo)
		move_and_slide()
		return

	# --- ALTERAÇÃO AQUI: Lógica direta ---
	var direcao_alvo = Vector2.ZERO
	
	if is_instance_valid(player):
		# Pega a direção direta para o player em vez de usar o NavigationAgent
		direcao_alvo = global_position.direction_to(player.global_position)

	if direcao_alvo.length() > 0:
		var velocidade_desejada = direcao_alvo * velocidade * Global.fator_tempo
		var forca_direcao = velocidade_desejada - velocity
		forca_direcao = forca_direcao.limit_length(forca_maxima_direcao)
		velocity += forca_direcao * delta * Global.fator_tempo
		velocity = velocity.limit_length(velocidade * Global.fator_tempo)
	else:
		velocity = velocity.lerp(Vector2.ZERO, delta * 3.0 * Global.fator_tempo)

	move_and_slide()
	
	update_animation_and_flip()
	
	if is_instance_valid(player) and (player.global_position - global_position).length() < 500:
		shoot()

# Função makepath removida pois não é mais necessária

func update_animation_and_flip():
	if velocity.length() > 10:
		sprite.play("andando")
		if velocity.x > 0: sprite.flip_h = false
		elif velocity.x < 0: sprite.flip_h = true


func aplicar_knockback(direcao: Vector2):
	knockback = true
	tempo_knockback = 0.0
	velocity = direcao * forca_knockback*2/3

func _on_collision_area_body_entered(body: Node2D) -> void:
	if knockback or body == self:
		return
	if body.is_in_group("player"):
		var direcao = (global_position - body.global_position).normalized()
		aplicar_knockback(direcao)
		if body.has_method("take_damage"):
			body.take_damage(1)

func shoot():
	sprite.play("atirando")
	if timer >= 4:
		var new_bullet = obj_tiro_azul.instantiate()
		var direction = (player.global_position - global_position).normalized()
		new_bullet.global_position = global_position
		new_bullet.velocity = direction * 150 
		get_parent().add_child(new_bullet)
		timer = 0.0

func take_damage(_amount: int) -> void:	
	queue_free()
