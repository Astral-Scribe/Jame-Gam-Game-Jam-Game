extends CharacterBody2D

enum State { MECH, RAT }
var current_state: State = State.MECH

@export_category("Mech Form Stats")
@export var mech_speed: float = 60.0
@export var mech_charge_speed: float = 160.0    
@export var mech_contact_damage: float = 1.0
@export var mech_health: float = 10.0
@export var mech_knockback_force: float = 220.0

@export_category("Rat Form Stats")
@export var rat_health: float = 1.0              
@export var rat_contact_damage: float = 0.0       
@export var rat_knockback_force: float = 0.0

@export_category("Global Physics")
@export var fall_velocity: float = 300.0

var wall_turn_cooldown: float = 0.0
const wall_turn_cooldown_duration: float = 0.25 

@export var rear_detection_range: float = 50.0 
var move_direction: float = -1.0

var is_charging: bool = false

@onready var animated_sprite: AnimatedSprite2D = $BossAnimator
@onready var player_detector: RayCast2D = $PlayerDetector
@onready var wall_detector: RayCast2D = $WallDetector
@onready var contact_hitbox: Area2D = $MechContactHitbox

@onready var main_collision_shape: CollisionShape2D = $Mech_Movement
@onready var rat_hurtbox: Area2D = $RatHurtbox 

func _ready() -> void:
	contact_hitbox.area_entered.connect(_on_contact_hitbox_entered)
	if rat_hurtbox:
		rat_hurtbox.area_entered.connect(_on_rat_hurtbox_entered)
		rat_hurtbox.set_deferred("monitoring", false)
		rat_hurtbox.set_deferred("monitorable", false)
	sync_sensors()

func _physics_process(delta: float) -> void:
	if wall_turn_cooldown > 0.0:
		wall_turn_cooldown = maxf(wall_turn_cooldown - delta, 0.0)
	
	var is_grounded: bool = false
	if current_state == State.MECH:
		is_grounded = is_on_floor()
	else:
		is_grounded = check_if_rat_is_on_floor()
	
	if not is_grounded:
		velocity += get_gravity() * delta
		if (velocity.y > fall_velocity):
			velocity.y = fall_velocity
	else:
		velocity.y = 0.0
			
	match current_state:
		State.MECH:
			sync_sensors()
			
			if player_detector.is_colliding():
				var target_area = player_detector.get_collider()
				if target_area and target_area.has_method("take_damage"):
					is_charging = true
				else:
					is_charging = false
			else:
				is_charging = false
			
			var current_speed: float = mech_charge_speed if is_charging else mech_speed
			velocity.x = move_direction * current_speed
			animated_sprite.flip_h = (move_direction > 0.0)
			
			var hit_wall: bool = wall_detector.is_colliding()
			
			if check_for_player_behind():
				return
			
			if hit_wall and wall_turn_cooldown <= 0.0:
				invert_patrol_direction()
				wall_turn_cooldown = wall_turn_cooldown_duration
				is_charging = false 
				return
		State.RAT:
			velocity.x = 0.0
			
	if current_state == State.MECH:
		move_and_slide()
	else:
		var _collision_info = move_and_collide(velocity * delta)
		
	update_enemy_animations()

func check_if_rat_is_on_floor() -> bool:
	if not rat_hurtbox:
		return false
	var overlapping_bodies = rat_hurtbox.get_overlapping_bodies()
	for body in overlapping_bodies:
		if body is TileMapLayer:
			return true
		if body.has_method("get_collision_layer_value") and body.get_collision_layer_value(1):
			return true
	return false

func invert_patrol_direction() -> void:
	move_direction *= -1.0
	sync_sensors()

func sync_sensors() -> void:
	if player_detector:
		player_detector.target_position.x = move_direction * absf(player_detector.target_position.x)
	if is_inside_tree() and wall_detector:
		wall_detector.target_position.x = move_direction * absf(wall_detector.target_position.x)

func check_for_player_behind() -> bool:
	if is_charging:
		return false

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
			invert_patrol_direction()
			return true
		
	return false

func update_enemy_animations() -> void:
	match current_state:
		State.MECH: 
			# Optional: Play a faster animation profile if charging!
			animated_sprite.play("mech")
		State.RAT: 
			animated_sprite.play("rat")

func _on_contact_hitbox_entered(player_hurtbox: Area2D) -> void:
	if current_state == State.RAT:
		return

	var player_body = player_hurtbox.get_parent() as CharacterBody2D
	if player_body and "is_diving" in player_body and player_body.is_diving:
		return 

	if player_hurtbox.has_method("take_damage"):
		player_hurtbox.take_damage(mech_contact_damage)
		apply_player_knockback(player_hurtbox, mech_knockback_force * 0.7)

func _on_rat_hurtbox_entered(incoming_player_attack: Area2D) -> void:
	if current_state == State.RAT and incoming_player_attack.name == "divehitbox":
		take_damage(1.0)

func take_damage(amount: float) -> void:
	match current_state:
		State.MECH:
			mech_health -= amount
			if mech_health <= 0.0:
				trigger_rat_transformation()
		State.RAT:
			rat_health -= amount
			if rat_health <= 0.0:
				win_game()

func trigger_rat_transformation() -> void:
	current_state = State.RAT
	is_charging = false
	main_collision_shape.set_deferred("disabled", true)
	if player_detector: player_detector.set_deferred("enabled", false)
	if wall_detector: wall_detector.set_deferred("enabled", false)
	animated_sprite.play("rat")
	if rat_hurtbox:
		rat_hurtbox.set_deferred("monitoring", true)
		rat_hurtbox.set_deferred("monitorable", true)

func win_game() -> void:
	get_tree().change_scene_to_file("res://scenes/win.tscn")
	queue_free()

func apply_player_knockback(player_hurtbox: Area2D, force: float) -> void:
	var player_body: CharacterBody2D = player_hurtbox.get_parent() as CharacterBody2D
	if player_body:
		var push_dir: float = signf(player_body.global_position.x - global_position.x)
		player_body.velocity.x = (push_dir if push_dir != 0.0 else 1.0) * force
		player_body.velocity.y = -100.0
