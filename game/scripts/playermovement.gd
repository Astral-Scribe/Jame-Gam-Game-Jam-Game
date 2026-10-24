
extends CharacterBody2D

@export var speed: float = 100.0
@export var jump_velocity: float = -220.0
@export var dash_amount: int = 1
@export var dash_velocity: float = 600.0
@export var dash_duration: float = 0.15
@export var dash_cooldown_duration: float = 0.1
@export var coyote_time_duration: float = 0.15
@export var idle_delay: float = 0.2
@export var jump_sustain: float = 500.0
@export var jump_sustain_duration: float = 0.25
@export var fall_velocity: float = 300.0

var jump_sustain_timer: float = 0.0
var dashes_used: int = 0
var is_dashing: bool = false
var jump_sustaining: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: float = 1.0
var coyote_timer: float = 0.0
var last_facing_direction: float = 1.0
var idle_buffer_timer: float = 0.0
var last_direction_key_pressed: String = ""
@onready var animated_sprite: AnimatedSprite2D = $PlayerAnimator

func _physics_process(delta: float) -> void:
	# Save whether on floor before movement to stop jank
	var was_on_floor: bool = is_on_floor()
	
	# Clamp the dash cooldown to 0 at minimum
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer = maxf(
			dash_cooldown_timer - delta, 0.0
		)

	# Count down dash duration
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false

	# Apply gravity
	if not was_on_floor and not is_dashing:
		velocity += get_gravity() * delta
		if (velocity.y > fall_velocity):
			velocity.y = fall_velocity
		coyote_timer = maxf(coyote_timer - delta, 0.0)
	elif was_on_floor:
		coyote_timer = coyote_time_duration
		dashes_used = 0
	
	# Jump, set sustaining to true until stop holding
	if Input.is_action_just_pressed("jump"):
		if was_on_floor or coyote_timer > 0.0:
			jump_sustaining = true
			jump_sustain_timer = jump_sustain_duration
			velocity.y = jump_velocity
			coyote_timer = 0.0

	# Clear sustaining on release
	if Input.is_action_just_released("jump"):
		jump_sustaining = false
	
	# Apply upwards sustain while holding and moving up
	if jump_sustaining and velocity.y < 0.0:
		if jump_sustain_timer > 0.0:
			velocity.y -= jump_sustain * delta
			jump_sustain_timer -= delta
	else:
		jump_sustaining = false
	
	# Movement Logging
	if Input.is_action_just_pressed("move_left"):
		last_direction_key_pressed = "left"
	elif Input.is_action_just_pressed("move_right"):
		last_direction_key_pressed = "right"

	var direction: float = 0.0
	var left_held: bool = Input.is_action_pressed("move_left")
	var right_held: bool = Input.is_action_pressed("move_right")
	
	# Get overall direction in case of conflict
	if left_held and right_held:
		direction = (
			-1.0 if last_direction_key_pressed == "left"
			else 1.0
		)
	elif left_held:
		direction = -1.0
	elif right_held:
		direction = 1.0

	# Begin dash if not dashing, has a dash, and dash not on cd 
	if (
		Input.is_action_just_pressed("dash")
		and not is_dashing
		and dashes_used < dash_amount
		and dash_cooldown_timer <= 0.0
	):
		dash_direction = (
			direction if direction != 0.0
			else last_facing_direction
		)
		# Hard-set direction, update sprite
		last_facing_direction = dash_direction
		animated_sprite.flip_h = dash_direction < 0.0

		# Set relevant fields
		is_dashing = true
		dash_timer = dash_duration
		dash_cooldown_timer = dash_cooldown_duration
		dashes_used += 1
		
		# Set velocity on x - locks speed
		velocity.x = dash_direction * dash_velocity
		velocity.y = 0.0
	
	# If dashing, lock X vel to dash speed and Y vel to 0
	if is_dashing:
		velocity.x = dash_direction * dash_velocity
		velocity.y = 0.0
	else:
		if direction != 0.0:
			# Update sprite flip, move
			idle_buffer_timer = idle_delay
			last_facing_direction = direction
			animated_sprite.flip_h = direction < 0.0
			velocity.x = direction * speed
		else:
			# Slow down when not holding a direction
			velocity.x = move_toward(
				velocity.x, 0.0, speed
			)
			idle_buffer_timer = maxf(
				idle_buffer_timer - delta, 0.0
			)
	
	# Update player location
	move_and_slide()
	
	# Reset dashes
	if is_on_floor():
		dashes_used = 0

	update_animations(direction)


func update_animations(direction: float) -> void:
	if is_dashing:
		animated_sprite.play("dash")
	elif not is_on_floor():
		if velocity.y < 0.0:
			# Moving upwards
			animated_sprite.play("jump")
		else:
			# Moving downwards
			animated_sprite.play("fall")
	else:
		if (
			direction != 0.0
			or absf(velocity.x) > 1.0
			or idle_buffer_timer > 0.0
		):
			animated_sprite.play("walk")
		else:
			animated_sprite.play("idle")
