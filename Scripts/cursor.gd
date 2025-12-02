extends CharacterBody2D

@export var velocidade: float = 200.0
@export var raio_da_roda: float = 170.0
var tween_dano: Tween

func _ready() -> void:
	add_to_group("player")
	velocidade = 200.0
func _physics_process(delta: float):
	var direcao = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direcao * velocidade
	move_and_slide()

	if position.length() > raio_da_roda:
		position = position.limit_length(raio_da_roda)

func take_damage(float):
	if tween_dano:
		tween_dano.kill()
		modulate = Color(2.5, 0.0, 0.0, 1.0) 
		tween_dano = create_tween()
		tween_dano.tween_property(self, "modulate", Color.WHITE, 0.15).set_trans(Tween.TRANS_SINE)
	if velocidade > 10:
		velocidade -= float * 5
	else:
		velocidade = velocidade/2
