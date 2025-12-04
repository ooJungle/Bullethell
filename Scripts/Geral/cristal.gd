extends StaticBody2D 
signal fui_quebrado

@export var vida_maxima = 100
var vida_atual = 0

# Referência ao material do sprite para controlar o shader
@onready var sprite = $Sprite2D 
var tempo_sem_laser: float = 0.0

func _ready():
	vida_atual = vida_maxima
	add_to_group("cristais") 
	add_to_group("cristal") 

func _process(delta: float) -> void:
	# Lógica para desligar o shader se o laser parar de bater
	if tempo_sem_laser > 0.1: # Se passar 0.1s sem receber laser
		if sprite.material:
			sprite.material.set_shader_parameter("ativo", false)
	else:
		tempo_sem_laser += delta

func take_damage(amount: int) -> void:
	# Aqui mantemos o flash branco SÓ para dano real (tiro do player)
	vida_atual -= amount
	modulate = Color(10, 10, 10) # Flash de dano
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	
	if vida_atual <= 0:
		quebrar()

# Função chamada pelo Laser do Inimigo (todo frame enquanto acerta)
func brilhar_impacto():
	tempo_sem_laser = 0.0 # Reseta o timer pois está recebendo laser
	if sprite.material:
		sprite.material.set_shader_parameter("ativo", true)

func quebrar():
	emit_signal("fui_quebrado")
	queue_free()
