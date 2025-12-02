# Script: projetil_espiral.gd
extends Area2D

# Carregamos a "peça" que vai formar a nossa espiral
const PontoDaEspiral = preload("res://Cenas/Projeteis/Ponto_Espiral.tscn") # Ajuste o caminho!

# A velocidade de todo o conjunto
var velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	# --- LÓGICA PARA CONSTRUIR A ESPIRAL ---
	var numero_de_pontos = 50
	var separacao_angular = 20.0
	var incremento_raio = 2.0

	for i in range(numero_de_pontos):
		var novo_ponto = PontoDaEspiral.instantiate()

		var angulo = i * separacao_angular
		var raio = i * incremento_raio

		var offset = Vector2.RIGHT.rotated(deg_to_rad(angulo)) * raio

		# Adicionamos o ponto como um filho DESTE nó, formando o corpo da espiral
		add_child(novo_ponto)
		novo_ponto.position = offset

	await get_tree().create_timer(20.0).timeout
	if is_instance_valid(self):
		queue_free()

func _physics_process(delta: float) -> void:
	# Move o conjunto inteiro (o "carro de LEGO") em linha reta
	position += velocity * delta
