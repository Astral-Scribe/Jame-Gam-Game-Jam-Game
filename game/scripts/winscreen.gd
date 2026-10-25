extends Control

@onready var play_again_button = $playagain
@onready var main_menu_button = $mainmenu
@onready var quit_button = $quit


func _ready() -> void:
	play_again_button.pressed.connect(_on_play_again_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	

func _on_play_again_pressed()-> void:
	get_tree().change_scene_to_file("res://scenes/level.tscn")

func _on_main_menu_pressed()-> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_quit_pressed()-> void:
	get_tree().quit()
