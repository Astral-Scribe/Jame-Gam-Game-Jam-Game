extends CharacterBody2D

enum State {idle, walk, bite}
var current_state: State = State.walk

#wolf stats
@export var speed: float = 60.0
@export var contact_damage: float = 1.0
@export var bite_damage: float = 1.0
@export var health: float = 3.0
@export var fall_velocity: float = 300.0
@export var knockback_force: float = 220.0

const idle_duration: float = 1.5
var idle_timer: float = 0.0
var move_direction: float = -1.0

#node references
@onready var animated_sprite: AnimatedSprite2D = $WolfAnimator
@onready var player_detector: RayCast2D = $PlayerDetector
@onready var contact_hitbox: Area2D = $WolfHitbox
@onready var bite_hitbox: Area2D = $BiteHitbox


func _ready() -> void:
	contact_hitbox.area_entered.connect(_on_contact_hitbox_entered)
	bite_hitbox.area_entered.connect(_on_bite_hitbox_entered)
	animated_sprite.animation_finished.connect(_on_animation_finished)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		if (velocity.y > fall_velocity):
			velocity.y = fall_velocity
		
	player_detector.target_position.x = move_direction * absf(player_detector.target_position.x)
		
	match current_state:
		State.idle:
			velocity.x = 0.0
			idle_timer -= delta
			if idle_timer <= 0.0:
				move_direction *= -1.0
				current_state = State.walk
			if player_detector.is_colliding():
				current_state = State.bite
			
		State.walk:
			velocity.x = move_direction * speed
			animated_sprite.flip_h = (move_direction > 0.0)
			if is_on_wall():
				current_state = State.idle
				idle_timer = idle_duration
			if player_detector.is_colliding():
				current_state = State.bite
		
		State.bite:
			velocity.x = move_toward(velocity.x, 0.0, speed)
		
	move_and_slide()
	update_wolf_animations()

func update_wolf_animations() -> void:
	match current_state:
		State.idle: animated_sprite.play("idle")
		State.walk: animated_sprite.play("walk")
		State.bite: animated_sprite.play("bite")

func _on_contact_hitbox_entered(player_hurtbox: Area2D) -> void:
	if current_state != State.bite and player_hurtbox.has_method("take_damage"):
		player_hurtbox.take_damage(contact_damage)
		apply_player_knockback(player_hurtbox, knockback_force * 0.7)

func _on_bite_hitbox_entered(player_hurtbox: Area2D) -> void:
	if current_state == State.bite and player_hurtbox.has_method("take_damage"):
		player_hurtbox.take_damage(bite_damage)
		apply_player_knockback(player_hurtbox, knockback_force)

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0.0:
		queue_free()

func apply_player_knockback(player_hurtbox: Area2D, force: float) -> void:
	var player_body: CharacterBody2D = player_hurtbox.get_parent() as CharacterBody2D
	if player_body:
		var push_dir: float = signf(player_body.global_position.x - global_position.x)
		player_body.velocity.x = (push_dir if push_dir != 0.0 else 1.0) * force
		player_body.velocity.y = -100.0

func _on_animation_finished() -> void:
	if current_state == State.bite:
		current_state = State.walk
