extends Control

@export var settings_menu_scene: PackedScene
@onready var video_player: VideoStreamPlayer = $CanvasLayer/PauseVideo
@onready var despause_video_player: VideoStreamPlayer = $CanvasLayer/DespauseVideo
@onready var menu_container: CanvasLayer = $CanvasLayer
@onready var resume_button: TextureButton = $CanvasLayer/VBoxContainer/ResumeButton
@onready var quit_button: TextureButton = $CanvasLayer/VBoxContainer/QuitButton
@onready var settings_button: TextureButton = $CanvasLayer/VBoxContainer/SettingsButton
@onready var options: VBoxContainer = $CanvasLayer/VBoxContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
func start_pause() -> void:
	Global.menu = 1
	Global.set_in_menu_state(true)
	menu_container.show()
	
	Global.paused = true
	get_tree().paused = true
	
	options.hide()
	despause_video_player.hide()
	video_player.show()
	video_player.stop() #pra rebobinar
	video_player.play()

func _on_resume_button_pressed() -> void:
	options.hide()
	despause_video_player.show()
	despause_video_player.stop()
	despause_video_player.play()

func _on_quit_button_pressed() -> void:
	Global.set_in_menu_state(true)
	Global.paused = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Cenas/Menu/MainMenu.tscn")

func _on_pause_video_finished() -> void:
	video_player.hide()
	options.show()

func _on_pause_video_2_finished() -> void:
	Global.set_in_menu_state(false)
	despause_video_player.hide()
	menu_container.hide()
	Global.paused = false
	get_tree().paused = false

func _on_settings_button_pressed() -> void:
	Transicao.transition()
	await Transicao.on_transition_finished 
	options.hide()
	var settings_instance = settings_menu_scene.instantiate()
	add_child(settings_instance)
	settings_instance.tree_exiting.connect(_on_settings_menu_closed)
	
func _on_settings_menu_closed():
	Transicao.transition()
	await Transicao.on_transition_finished
	options.show()
