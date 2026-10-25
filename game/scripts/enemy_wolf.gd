extends CharacterBody2D

enum State {idle, walk, bite}
var current_state: State = State.walk

# Wolf Stats
@export var speed: float = 60.0
@export var lunge_speed: float = 150.0
@export var contact_damage: float = 1.0
@export var bite_damage: float = 1.0
@export var health: float = 3.0
@export var fall_velocity: float = 300.0
@export var knockback_force: float = 220.0

@export var bite_duration: float = 0.4
@export var bite_cooldown_duration: float = 1.0
var bite_timer: float = 0.0
var bite_cooldown_timer: float = 0.0

var ledge_turn_cooldown: float = 0.0
const ledge_turn_cooldown_duration: float = 0.25 
var wall_turn_cooldown: float = 0.0
const wall_turn_cooldown_duration: float = 0.25 

@export var rear_detection_range: float = 50.0 

const idle_duration: float = 1.5
var idle_timer: float = 0.0
var move_direction: float = -1.0

# Node references
@onready var animated_sprite: AnimatedSprite2D = $WolfAnimator
@onready var player_detector: RayCast2D = $PlayerDetector
@onready var ledge_detector: RayCast2D = $LedgeDetector
@onready var wall_detector: RayCast2D = $WallDetector
@onready var contact_hitbox: Area2D = $WolfHitbox
@onready var bite_hitbox: Area2D = $BiteHitbox

func _ready() -> void:
	contact_hitbox.area_entered.connect(_on_contact_hitbox_entered)
	bite_hitbox.area_entered.connect(_on_bite_hitbox_entered)
	sync_sensors()

func _physics_process(delta: float) -> void:
	# 1. Handle Cooldown Timers
	if bite_cooldown_timer > 0.0:
		bite_cooldown_timer = maxf(bite_cooldown_timer - delta, 0.0)
	if ledge_turn_cooldown > 0.0:
		ledge_turn_cooldown = maxf(ledge_turn_cooldown - delta, 0.0)
	if wall_turn_cooldown > 0.0:
		wall_turn_cooldown = maxf(wall_turn_cooldown - delta, 0.0)
	
	if not is_on_floor():
		velocity += get_gravity() * delta
		if (velocity.y > fall_velocity):
			velocity.y = fall_velocity
	else:
		if current_state == State.idle:
			velocity.x = 0.0
			
	sync_sensors()
	
	match current_state:
		State.idle:
			velocity.x = move_toward(velocity.x, 0.0, speed)
			idle_timer -= delta
			if idle_timer <= 0.0:
				current_state = State.walk
			if player_detector.is_colliding() and bite_cooldown_timer <= 0.0:
				trigger_bite_attack()
				
			check_for_player_behind()
		
		State.walk:
			velocity.x = move_direction * speed
			
			animated_sprite.flip_h = (move_direction < 0.0)
			
			var hit_wall: bool = wall_detector.is_colliding()
			var hit_ledge: bool = is_on_floor() and not ledge_detector.is_colliding()
			
			if check_for_player_behind():
				return

			if hit_wall and wall_turn_cooldown <= 0.0:
				move_direction *= -1.0
				wall_turn_cooldown = wall_turn_cooldown_duration
				ledge_turn_cooldown = ledge_turn_cooldown_duration 
				sync_sensors() 
				current_state = State.idle
				idle_timer = idle_duration
				velocity.x = 0.0
				return
				
			if hit_ledge and ledge_turn_cooldown <= 0.0 and wall_turn_cooldown <= 0.0:
				move_direction *= -1.0
				ledge_turn_cooldown = ledge_turn_cooldown_duration
				wall_turn_cooldown = wall_turn_cooldown_duration 
				sync_sensors()
				velocity.x = move_direction * speed
				animated_sprite.flip_h = (move_direction < 0.0)
				return
				
			if player_detector.is_colliding() and bite_cooldown_timer <= 0.0:
				trigger_bite_attack()
		
		State.bite:
			velocity.x = move_toward(velocity.x, move_direction * lunge_speed, speed * 2.0)
			bite_timer -= delta
			if bite_timer <= 0.0:
				bite_cooldown_timer = bite_cooldown_duration
				current_state = State.walk
		
	move_and_slide()
	update_wolf_animations()

func trigger_bite_attack() -> void:
	current_state = State.bite
	bite_timer = bite_duration
	animated_sprite.play("bite")

func sync_sensors() -> void:
	player_detector.target_position.x = move_direction * absf(player_detector.target_position.x)
	ledge_detector.position.x = move_direction * absf(ledge_detector.position.x)
	if is_inside_tree() and wall_detector:
		wall_detector.target_position.x = move_direction * absf(wall_detector.target_position.x)

func check_for_player_behind() -> bool:
	if player_detector.is_colliding():
		var detected_area = player_detector.get_collider()
		if detected_area and detected_area.has_method("take_damage"):
			return false 

	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.new()
	
	query.from = global_position
	query.to = global_position + Vector2(-move_direction * rear_detection_range, 0.0)
	
	query.collision_mask = player_detector.collision_mask
	query.collide_with_areas = true
	query.collide_with_bodies = false
	
	var result = space_state.intersect_ray(query)
	if result:
		var hit_area = result.collider
		if hit_area and absf(hit_area.global_position.y - global_position.y) < 20.0:
			move_direction *= -1.0
			sync_sensors()
			current_state = State.walk
			return true
		
	return false

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
