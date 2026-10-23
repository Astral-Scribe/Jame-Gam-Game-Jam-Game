extends CharacterBody2D


const speed: float = 100.0
const jump_velocity: float = -400.0
var dash_amount: int = 1
var dashes_used: int = 0
const dash_velocity: float = 500.0
const dash_cooldown_duration: float = 0.1
var dash_cooldown_timer: float = 0.0
const coyote_time_duration: float = 0.15
var coyote_timer: float = 0.0
@onready var animated_sprite: AnimatedSprite2D = $PlayerAnimator

var is_dashing: bool = false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		coyote_timer -= delta
	else:
		coyote_timer = coyote_time_duration
		dashes_used = 0
		
	if Input.is_action_just_pressed("jump") and (is_on_floor() or coyote_timer > 0.0):
		velocity.y = jump_velocity
		coyote_timer = 0.0

	var direction: float = Input.get_axis("move_left", "move_right")

	if dash_cooldown_timer <= 0.0 or direction == 0.0:
		is_dashing = false

	if direction != 0.0:
		animated_sprite.flip_h = (direction < 0.0)

		if Input.is_action_just_pressed("dash") and (dashes_used < dash_amount) and dash_cooldown_timer <= 0.0:
			velocity.x = direction * dash_velocity
			dashes_used += 1
			dash_cooldown_timer = dash_cooldown_duration
			is_dashing = true
		else:
			if not is_dashing:
				velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
	
	move_and_slide()
	dash_cooldown_timer -= delta
	
	update_animatioons(direction)

func update_animatioons(direction: float) -> void:
	if is_dashing:
		animated_sprite.play("dash")
	elif not is_on_floor():
		if velocity.y < 0.0:
			animated_sprite.play("jump")
		else:
			animated_sprite.play("fall")
	else: 
		if direction != 0.0:
			animated_sprite.play("walk")
		else:
			animated_sprite.play("idle")
