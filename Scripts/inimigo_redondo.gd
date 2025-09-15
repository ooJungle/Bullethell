extends CharacterBody2D
@export var velocidade = 90.0
@onready var sprite: AnimatedSprite2D = $sprite
@export var player = Node2D
const obj_tiro_roxo = preload("res://Cenas/tiro_roxo.tscn")

var girar = true
var timer = 0.0
var knockback = false
var tempo_knockback = 0.0
var tempo_entre_tiros = 0.0
var limite_projeteis = 0
var rotacao = 200
var atirando = false
var direction: Vector2 = Vector2.ZERO
func shoot(velocidade_tiro: float):
	if not atirando:
		direction = (player.position - position).normalized()
	if timer >= 1.2:
		atirando = true
		if tempo_entre_tiros > 0.01:
			rotacao += 0.1
			var new_bullet = obj_tiro_roxo.instantiate()
			new_bullet.position = position
			new_bullet.velocity = (direction * velocidade_tiro).rotated(rotacao)
			get_parent().add_child(new_bullet)
			limite_projeteis += 1
			tempo_entre_tiros = 0.0
		if limite_projeteis > 30:
			timer = 0.0
			limite_projeteis = 0
			rotacao = 200
			atirando = false

func _physics_process(delta: float) -> void:
	timer += delta
	tempo_entre_tiros += delta
	var direction = (player.position - position).normalized()
	look_at(player.position)
	
	# só anda se não estiver em knockback
	if not knockback:
		velocity = direction * velocidade

	# checa colisão apenas para iniciar knockback
	if not knockback:
		var nearby = get_tree().get_nodes_in_group("enemies") + get_tree().get_nodes_in_group("players")
		for other in nearby:
			if other == self:
				continue
			var dist = (other.position - position)
			if dist.length() <= 17:
				position -= velocity * delta * 10
				knockback = true
				tempo_knockback = 0.0
				break  # sai do loop para não reativar no mesmo frame

	# processa o estado de knockback
	if knockback:
		tempo_knockback += delta
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
	if girar:
		sprite.rotate(-3.14/2)
		girar = false
