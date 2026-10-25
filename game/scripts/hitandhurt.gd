extends Area2D

signal health_changed(new_health: float)
signal mana_changed(new_mana: float)
#player stats
var max_health: float = 3.0
var current_health: float = 3.0
var max_mana: float = 3.0
var current_mana: float = 3.0

@export var invincibility_duration: float = 0.5
var is_invincible: bool = false
@onready var invincibility_timer: Timer = $InvincibilityTimer

#healing variables
var heal_cast_delay_length: float = 0.5
var heal_cast_timer: float = 0.0
var is_casting_heal: bool = false

func _ready() -> void:
	current_health = max_health
	current_mana = max_mana
	invincibility_timer.timeout.connect(_on_invincibility_timeout)

func _physics_process(delta: float) -> void:
	handle_heal_casting(delta)

func take_damage(amount):
	if is_invincible:
		return
	current_health -= amount
	health_changed.emit(current_health)
	if current_health <= 0.0:
		die_and_respawn()
		return 
	is_invincible = true
	invincibility_timer.start(invincibility_duration)
	if is_casting_heal:
		cancel_heal()

func die_and_respawn() -> void:
		get_tree().call_deferred("reload_current_scene")

func _on_invincibility_timeout() -> void:
	is_invincible = false

func use_mana(amount) -> bool:	
	if amount <= current_mana:
		current_mana -= amount
		mana_changed.emit(current_mana)
		return true
	return false

func handle_heal_casting(delta: float) -> void:
	if Input.is_action_pressed("heal") and current_health < max_health:
		if not is_casting_heal:
			if use_mana(1.0):
				is_casting_heal = true
				heal_cast_timer = 0.0
			else:
				return
		if is_casting_heal:
			heal_cast_timer += delta
			if heal_cast_timer >= heal_cast_delay_length:
				current_health = min(current_health + 1.0, max_health)
				health_changed.emit(current_health)
				is_casting_heal = false
				heal_cast_timer = 0.0
	else:
		if is_casting_heal and not Input.is_action_pressed("heal"):
			cancel_heal()

func cancel_heal() -> void:
	is_casting_heal = false
	heal_cast_timer = 0.0
