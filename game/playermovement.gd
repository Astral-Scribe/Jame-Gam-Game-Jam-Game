extends CharacterBody2D


const speed: float = 300.0
const jump_velocity: float = -400.0
const coyote_time_duration: float = 0.15
var coyote_timer: float = 0.0


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		coyote_timer -= delta
	else:
		coyote_timer = coyote_time_duration

	if Input.is_action_just_pressed("jump") and (is_on_floor() or coyote_timer > 0.0):
		velocity.y = jump_velocity
		coyote_timer = 0.0

	var direction: float = Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)

	move_and_slide()
