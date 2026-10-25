extends Control

@onready var play_button = $MenuContainer/Play
@onready var controls_button = $MenuContainer/Controls
@onready var credits_button = $MenuContainer/Credits
@onready var quit_button = $MenuContainer/Quit
@onready var controls_panel: Panel = $ControlsPanel 
@onready var credits_panel: Panel = $CreditsPanel
@onready var controls_back_button: Button = $ControlsPanel/BackButton
@onready var credits_back_button: Button = $CreditsPanel/BackButton

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	controls_button.pressed.connect(_on_controls_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	controls_back_button.pressed.connect(_on_controls_back_pressed)
	credits_back_button.pressed.connect(_on_credits_back_pressed)
	controls_panel.visible = false
	credits_panel.visible = false

func _on_play_pressed()-> void:
	get_tree().change_scene_to_file("res://scenes/level.tscn")

func _on_controls_pressed()-> void:
	controls_panel.visible = true

func _on_credits_pressed()-> void:
	credits_panel.visible = true

func _on_quit_pressed()-> void:
	get_tree().quit()

func _on_controls_back_pressed() -> void:
	controls_panel.visible = false 

func _on_credits_back_pressed() -> void:
	credits_panel.visible = false
