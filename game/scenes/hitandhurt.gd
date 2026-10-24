extends CollisionShape2D

signal health_changed
signal mana_changed
var max_health: float = 3.0
var current_health: float = 3.0
var max_mana: float = 3.0
var current_mana: float = 3.0

func take_damage(amount):
	var old_health = current_health
	current_health -= amount
	health_changed.emit(old_health, current_health)

func use_mana(amount):
	if amount <= current_mana:
		current_mana -= amount
		mana_changed.emit(current_mana)
		return true
	else:
		return false

func heal():
	if current_health < max_health:
		if use_mana(1):
			current_health += 1
	
