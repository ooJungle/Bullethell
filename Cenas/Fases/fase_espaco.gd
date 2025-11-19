extends Node2D

@onready var portal_volta = $portal_volta
@onready var colisao_portal = $portal_volta/CollisionShape2D

var total_cristais = 0
var cristais_quebrados = 0

func _ready():
	portal_volta.visible = false
	colisao_portal.set_deferred("disabled", true)
	
	var lista_cristais = get_tree().get_nodes_in_group("cristais")
	total_cristais = lista_cristais.size()
	
	print("Fase iniciada. Total de cristais: ", total_cristais)
	
	for cristal in lista_cristais:
		cristal.fui_quebrado.connect(_on_cristal_quebrado)

func _on_cristal_quebrado():
	cristais_quebrados += 1
	print("Cristal quebrado! ", cristais_quebrados, "/", total_cristais)
	
	if cristais_quebrados >= total_cristais:
		abrir_portal()

func abrir_portal():
	print("Todos os cristais quebrados! Portal aberto.")
	portal_volta.visible = true
	colisao_portal.set_deferred("disabled", false)
