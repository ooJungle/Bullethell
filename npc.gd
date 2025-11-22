extends CharacterBody2D # Ou StaticBody2D, dependendo do seu NPC

# Escreva os textos direto no Inspector do Editor!
@export_multiline var falas_do_npc: Array[String] = [
	"Olá viajante!",
	"Os cristais foram corrompidos.",
	"Você precisa destruir todos eles para abrir o portal."
]

var player_na_area: bool = false

func _ready():
	# Conecte os sinais da Area2D via código ou editor
	$Area2D.body_entered.connect(_on_area_entered)
	$Area2D.body_exited.connect(_on_area_exited)

func _process(delta):
	# Se o player está perto e apertou o botão (Espaço/Enter ou sua tecla de interação)
	if player_na_area and Input.is_action_just_pressed("ui_accept"):
		# Chama o nosso sistema global
		Dialogo.start_dialogue(falas_do_npc)

func _on_area_entered(body):
	if body.is_in_group("players"):
		player_na_area = true
		# Opcional: Mostrar um ícone de "E" ou "!" sobre a cabeça

func _on_area_exited(body):
	if body.is_in_group("players"):
		player_na_area = false
