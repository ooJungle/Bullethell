extends Control

# Crie uma referência para o player de música do menu
@onready var menu_music_player = $MenuMusicPlayer

func _ready() -> void:
	Global.set_in_menu_state(true)
	Global.menu = 0
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true, 0)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true, 0)
	menu_music_player.volume_db = linear_to_db(Global.volume * 4)
	
	# Toca a música do menu (se ela não estiver no Autoplay)
	if not menu_music_player.playing:
		menu_music_player.play()

func _on_play_button_pressed() -> void:
	Global.set_in_menu_state(false)
	Transicao.transition()
	await Transicao.on_transition_finished
	get_tree().change_scene_to_file("res://Cenas/Fases/Fase_0.tscn")

func _on_settings_button_pressed() -> void:
	Transicao.transition()
	await Transicao.on_transition_finished
	get_tree().change_scene_to_file("res://Cenas/Menu/SettingsMenu.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_play_endless_button_pressed() -> void:
	Transicao.transition()
	await Transicao.on_transition_finished
	Global.set_in_menu_state(false)
	get_tree().change_scene_to_file("res://Cenas/Fases/fase_teste.tscn")
