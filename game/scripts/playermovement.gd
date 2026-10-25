extends CharacterBody2D

signal dash_status_changed(is_ready: bool)

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

@export var dive_ground_pop_velocity: float = -180.0 
@export var dive_downward_velocity: float = 450.0     
@export var dive_horizontal_velocity: float = 300.0   
@export var dive_damage: float = 1.0
var is_diving: bool = false
var has_ground_popped: bool = false
var dive_direction: float = 1.0                       

var is_healing: bool = false
var knockback_timer: float = 0.0

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

var dash_was_ready: bool = true

@onready var animated_sprite: AnimatedSprite2D = $PlayerAnimator
@onready var dive_hitbox: Area2D = $divehitbox

func _ready() -> void:
	if dive_hitbox:
		dive_hitbox.area_entered.connect(_on_dive_hitbox_area_entered)
	sync_dash_status()

func _physics_process(delta: float) -> void:
	var was_on_floor: bool = is_on_floor()
	
	if knockback_timer > 0.0:
		knockback_timer -= delta
	
	if was_on_floor and is_diving and not has_ground_popped:
		is_diving = false
		trigger_landing_iframes()

	var stats_node = get_node_or_null("hurtbox") as Area2D
	if stats_node and "is_casting_heal" in stats_node:
		is_healing = stats_node.is_casting_heal

	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer = maxf(dash_cooldown_timer - delta, 0.0)
		
	sync_dash_status()

	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false

	if Input.is_action_just_pressed("attack") and not is_dashing and not is_diving and not is_healing:
		is_diving = true
		dive_direction = last_facing_direction
		
		if was_on_floor:
			velocity.y = dive_ground_pop_velocity
			has_ground_popped = true
		else:
			velocity.y = dive_downward_velocity
			velocity.x = dive_direction * dive_horizontal_velocity
			has_ground_popped = false
			
	if not was_on_floor and not is_dashing and not (is_diving and not has_ground_popped):
		velocity += get_gravity() * delta
		
		if is_diving and has_ground_popped and velocity.y >= 0.0:
			velocity.y = dive_downward_velocity
			velocity.x = dive_direction * dive_horizontal_velocity
			has_ground_popped = false 
			
		if (velocity.y > fall_velocity) and not is_diving:
			velocity.y = fall_velocity
		elif is_diving and velocity.y > dive_downward_velocity:
			velocity.y = dive_downward_velocity
			
		coyote_timer = maxf(coyote_timer - delta, 0.0)
	elif was_on_floor:
		coyote_timer = coyote_time_duration
		dashes_used = 0
	
	# Jump handling
	if Input.is_action_just_pressed("jump") and not is_diving and not is_healing:
		if was_on_floor or coyote_timer > 0.0:
			jump_sustaining = true
			jump_sustain_timer = jump_sustain_duration
			velocity.y = jump_velocity
			coyote_timer = 0.0

	if Input.is_action_just_released("jump"):
		jump_sustaining = false
	
	if jump_sustaining and velocity.y < 0.0 and not is_diving:
		if jump_sustain_timer > 0.0:
			velocity.y -= jump_sustain * delta
			jump_sustain_timer -= delta
	else:
		jump_sustaining = false
	
	if Input.is_action_just_pressed("move_left"):
		last_direction_key_pressed = "left"
	elif Input.is_action_just_pressed("move_right"):
		last_direction_key_pressed = "right"

	var direction: float = 0.0
	var left_held: bool = Input.is_action_pressed("move_left")
	var right_held: bool = Input.is_action_pressed("move_right")
	
	if left_held and right_held:
		direction = (-1.0 if last_direction_key_pressed == "left" else 1.0)
	elif left_held:
		direction = -1.0
	elif right_held:
		direction = 1.0

	# Begin dash
	if (
		Input.is_action_just_pressed("dash")
		and not is_dashing
		and not is_diving
		and not is_healing
		and dashes_used < dash_amount
		and dash_cooldown_timer <= 0.0
	):
		dash_direction = (direction if direction != 0.0 else last_facing_direction)
		last_facing_direction = dash_direction
		animated_sprite.flip_h = dash_direction < 0.0

		is_dashing = true
		dash_timer = dash_duration
		dash_cooldown_timer = dash_cooldown_duration
		dashes_used += 1
		
		dash_was_ready = false
		dash_status_changed.emit(false)
		
		velocity.x = dash_direction * dash_velocity
		velocity.y = 0.0
	
	if knockback_timer > 0.0:
		move_and_slide()
	elif is_dashing:
		velocity.x = dash_direction * dash_velocity
		velocity.y = 0.0
		move_and_slide()
	elif is_diving:
		if has_ground_popped:
			if direction != 0.0:
				velocity.x = direction * speed
				last_facing_direction = direction
				animated_sprite.flip_h = (direction < 0.0)
			move_and_slide()
		else:
			velocity.x = dive_direction * dive_horizontal_velocity
			animated_sprite.flip_h = (dive_direction < 0.0)
			
			var collision_info = move_and_collide(velocity * delta)
			if collision_info:
				is_diving = false
				trigger_landing_iframes()
	elif is_healing:
		velocity.x = 0.0
		move_and_slide()
	else:
		if direction != 0.0:
			idle_buffer_timer = idle_delay
			last_facing_direction = direction
			animated_sprite.flip_h = (direction < 0.0)
			velocity.x = direction * speed
		else:
			velocity.x = move_toward(velocity.x, 0.0, speed)
			idle_buffer_timer = maxf(idle_buffer_timer - delta, 0.0)
		move_and_slide()
	
	if is_on_floor():
		dashes_used = 0
	update_animations(direction)

func _on_dive_hitbox_area_entered(enemy_hurtbox: Area2D) -> void:
	if is_diving and not has_ground_popped:
		var enemy_stats = enemy_hurtbox.get_parent()
		if enemy_stats.has_method("take_damage"):
			enemy_stats.take_damage(dive_damage)
			is_diving = false
			has_ground_popped = false
			velocity = Vector2.ZERO
			velocity.y = -200.0       
			velocity.x = -dive_direction * 120.0
			knockback_timer = 0.18
			trigger_landing_iframes()

func trigger_landing_iframes() -> void:
	var stats: Area2D = get_node_or_null("hurtbox") as Area2D
	if stats and "is_invincible" in stats and "invincibility_timer" in stats:
		stats.is_invincible = true
		stats.invincibility_timer.start(stats.invincibility_duration)

func sync_dash_status() -> void:
	var is_dash_available: bool = (dashes_used < dash_amount) and (dash_cooldown_timer <= 0.0)
	if is_dash_available and not dash_was_ready:
		dash_was_ready = true
		dash_status_changed.emit(true)

func update_animations(direction: float) -> void:
	if is_healing:
		animated_sprite.play("heal")
	elif is_diving:
		animated_sprite.play("jump" if has_ground_popped else "attack")
	elif is_dashing:
		animated_sprite.play("dash")
	elif not is_on_floor():
		animated_sprite.play("jump" if velocity.y < 0.0 else "fall")
	else:
		if (direction != 0.0 or absf(velocity.x) > 1.0 or idle_buffer_timer > 0.0):
			animated_sprite.play("walk")
		else:
			animated_sprite.play("idle")
