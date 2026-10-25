extends Control

#icon paths
const heart_full: Texture2D = preload("res://assets/ui/heart.png")
const heart_missing: Texture2D = preload("res://assets/ui/heart_empty.png")
const mana_full: Texture2D = preload("res://assets/ui/mana.png")
const mana_missing: Texture2D = preload("res://assets/ui/mana_empty.png")
const dash_full: Texture2D = preload("res://assets/ui/dash.png")
const dash_missing: Texture2D = preload("res://assets/ui/dash_empty.png")

#health, mana, dash containers
@onready var health_container: HBoxContainer = $Health_Container
@onready var mana_container: HBoxContainer = $Mana_Container
@onready var dash_icon: TextureRect = $Dash 


func _ready() -> void:
	var player: CharacterBody2D = get_parent() as CharacterBody2D
	if player:
		if player.has_signal("dash_status_changed"):
			player.dash_status_changed.connect(_on_player_dash_status_changed)
		var stats: Area2D = player.get_node_or_null("hitandhurt") as Area2D
		if stats:
			stats.health_changed.connect(_on_player_health_changed)
			stats.mana_changed.connect(_on_player_mana_changed)

func _on_player_health_changed(new_health: float) -> void:
	var hearts: Array[Node] = health_container.get_children()
	for i: int in range(hearts.size()):
		if hearts[i] is TextureRect:
			hearts[i].texture = heart_full if i < int(new_health) else heart_missing

func _on_player_mana_changed(new_mana: float) -> void:
	var mana: Array[Node] = mana_container.get_children()
	for i: int in range(mana.size()):
		if mana[i] is TextureRect:
			mana[i].texture = mana_full if i < int(new_mana) else mana_missing

func _on_player_dash_status_changed(is_ready: bool) -> void:
	if is_ready:
		dash_icon.texture = dash_full 
	else:
		dash_icon.texture = dash_missing
