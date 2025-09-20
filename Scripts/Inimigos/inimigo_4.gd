extends CharacterBody2D
@export var velocidade = 90.0
@onready var sprite: AnimatedSprite2D = $sprite
@export var player = Node2D
const obj_tiro_roxo = preload("res://Cenas/Projeteis/tiro_roxo.tscn")
const obj_tiro_azul = preload("res://Cenas/Projeteis/tiro_azul.tscn")
const obj_tiro_verde = preload("res://Cenas/Projeteis/tiro_verde.tscn")


var ataque_aleatorio = randi_range(0,4)
var timer = 0.0
var knockback = false
var tempo_knockback = 0.0
var tempo_entre_tiros = 0.0
var limite_projeteis = 0
var rotacao = 200
var atirando = false
var direcao_ataque_1: Vector2 = Vector2.ZERO





func shoot(velocidade_tiro: float):
	if ataque_aleatorio == 0:
		if not atirando:
			direcao_ataque_1 = (player.position - position).normalized()
		if timer >= 1.2:
			atirando = true
			if tempo_entre_tiros > 0.01:
				rotacao += 0.1
				var new_bullet = obj_tiro_roxo.instantiate()
				new_bullet.position = position
				new_bullet.velocity = (direcao_ataque_1 * velocidade_tiro).rotated(rotacao)
				get_parent().add_child(new_bullet)
				limite_projeteis += 1
				tempo_entre_tiros = 0.0
			if limite_projeteis > 30:
				timer = 0.0
				limite_projeteis = 0
				rotacao = 200
				atirando = false
				ataque_aleatorio = randi_range(0,4)
	if ataque_aleatorio == 1:
		if timer >= 5:
			for i in range(11):
					var new_bullet = obj_tiro_roxo.instantiate()
					var direction = (player.position - position).normalized().rotated((40 * i))
					new_bullet.position = position
					new_bullet.velocity = direction * velocidade_tiro
					get_parent().add_child(new_bullet)
			timer = 0.0
			ataque_aleatorio = randi_range(0,4)

	if ataque_aleatorio == 2:
		if timer >= 1.2:
			var new_bullet = obj_tiro_roxo.instantiate()
			var direction = (player.position - position).normalized()
			new_bullet.position = position
			new_bullet.velocity = direction * velocidade_tiro
			get_parent().add_child(new_bullet)
			timer = 0.0
			ataque_aleatorio = randi_range(0,4)

	if ataque_aleatorio == 3:
		if timer >= 1.2:
			var new_bullet = obj_tiro_azul.instantiate()
			var direction = (player.position - position).normalized()
			
			new_bullet.player = player
			new_bullet.position = position
			new_bullet.velocity = direction * velocidade
			get_parent().add_child(new_bullet)
			timer = 0.0
			ataque_aleatorio = randi_range(0,4)

	if ataque_aleatorio == 4:
		if timer >= 1.2:
			for i in range(4):
				var new_bullet = obj_tiro_verde.instantiate()
				var direction = (player.position - position).normalized()
				
				new_bullet.player = player
				new_bullet.position = Vector2.ZERO + position * i
				new_bullet.velocity = direction * velocidade
				get_parent().add_child(new_bullet)
			timer = 0.0
			ataque_aleatorio = randi_range(0,4)





func _physics_process(delta: float) -> void:
	if Global.paused:
		return
	timer += delta
	tempo_entre_tiros += delta
	var direction = (player.position - position).normalized()

	# só anda se não estiver em knockback
	if not knockback:
		velocity = direction * velocidade

	# checa colisão apenas para iniciar knockback
	if not knockback:
		var nearby = get_tree().get_nodes_in_group("players")
		for other in nearby:
			if other == self:
				continue
			var dist = (other.position - position)
			if dist.length() <= 17:
				velocity = -7 * velocity
				knockback = true
				tempo_knockback = 0.0
				break  # sai do loop para não reativar no mesmo frame

	# processa o estado de knockback
	if knockback:
		tempo_knockback += delta
		if tempo_knockback > 0.2:
			velocity = Vector2.ZERO
		if tempo_knockback >= 2.0:
			knockback = false
		
	move_and_slide()

	# Flip do sprite
	if velocity.x > 0:
		sprite.flip_h = false
	elif velocity.x < 0:
		sprite.flip_h = true	
	# Animação
	if velocity.length() > 0:
		sprite.play("Walking")
	else:
		sprite.play("Idle")
		
	if (player.position - position).length() < 500:
		shoot(130)
