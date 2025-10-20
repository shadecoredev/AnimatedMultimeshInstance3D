extends Node3D
class_name SwarmMovement

@export var body : MultimeshInstanceControl

@export var speed : float = 0.87

@export var is_enraged : bool = false
@export var enrage_chance : float = 0.01
@export var enrage_speed : float = 6.0
@export var enrage_animation : String = "Run"

@export var aggro_multiplier : float = 25.0
@export var aggro_range : float = 200.0

@export var max_climb_slope : float = PI * 0.6

var target : Node3D

var velocity : Vector3
var elevation : float = 0.5

var overlapping : bool = false

const rotation_axis = Vector3.UP

var last_process_timestamp : float = 0.0

var _elapsed_delta : float = 0.0
var _elapsed_ai_delta : float = 0.0
var __direction : Vector3

var _exclude_array : Array[RID]

var __attacking : bool = false

func _ready():
	if body:
		_exclude_array.append(body.get_rid())
	
	body.lazy_process_signal.connect(_lazy_process)
	body.ai_process_signal.connect(_ai_process)

	#area_entered.connect(_on_area_entered)
	#area_exited.connect(_on_area_exited)

func initialize_delta(elapsed_delta):
	_elapsed_delta = elapsed_delta

func _lazy_process(elapsed_delta):
	var delta : float = elapsed_delta - _elapsed_delta
	delta = min(delta, 0.5)
	_elapsed_delta = elapsed_delta

	### Movement logic

	body.position += velocity * delta

	### Multimesh transform logic

	var temp_direction : Vector3 = __direction
	temp_direction.x = -temp_direction.x
	body.rotate(
		rotation_axis,
		-global_basis.z.signed_angle_to(
			temp_direction,
			-rotation_axis
		) * delta * PI
	)

	body.update_transform()

func _ai_process(elapsed_delta):
	var delta : float = elapsed_delta - _elapsed_ai_delta
	delta = min(delta, 0.5)
	_elapsed_ai_delta = elapsed_delta

	if target:
		## Target movement
		__direction = target.global_position - body.global_position
		__direction.y = 0.0

		if __direction.length_squared() <= 1.5:
			velocity.x = 0.0
			velocity.z = 0.0
			if !__attacking:
				__attacking = true
				body._bulk_control.play_animation(body._instance_id, "Attack", 0.3, 1.0)
				create_tween().tween_callback(func():__attacking = false).set_delay(0.9)

		## Enrage
		if !is_enraged and randf() < enrage_chance * delta:
			is_enraged = true
			body._bulk_control.play_animation(body._instance_id, enrage_animation, 3.0)
			var speed_tween = create_tween()
			speed_tween.tween_property(self, "speed", enrage_speed, 3.0)
			
	else:
		## Idle movement
		var direction_angle : float = body.get_idle_noise(
			Vector3(
				global_position.x,
				global_position.z,
				_elapsed_ai_delta,
			)
		)
		__direction = Vector3.FORWARD.rotated(Vector3.UP, direction_angle * TAU * 2.0)
		
		## Aggro check
		var aggro_raycast_query = PhysicsRayQueryParameters3D.create(
			body.global_position + Vector3.UP,
			body.global_position + Vector3.UP + _get_look_cone_direction(__direction, PI * 0.5) * aggro_range,
			9, # World + Aggro
			_exclude_array
		)
		aggro_raycast_query.collide_with_areas = true

		var aggro_raycast_collision = get_world_3d().direct_space_state.intersect_ray(aggro_raycast_query)

		if !aggro_raycast_collision.is_empty():
			if aggro_raycast_collision.collider is FirstPersonController and  randf() < aggro_multiplier * delta:
				target = aggro_raycast_collision.collider
			
			if aggro_raycast_collision.collider is MultimeshInstanceControl and \
					aggro_raycast_collision.collider.ai.target and \
					(randf() < aggro_multiplier * delta or aggro_raycast_collision.collider.ai.is_enraged):
				target = aggro_raycast_collision.collider.ai.target

	## Collision raycast

	if !__attacking:
		var raycast_query = PhysicsRayQueryParameters3D.create(
			body.global_position + Vector3.UP,
			body.global_position + Vector3.UP + __direction.normalized() * 0.5,
			5, # Enemies + World
			_exclude_array
		)
		raycast_query.collide_with_areas = true
		raycast_query.hit_from_inside = true

		var raycast_collision = get_world_3d().direct_space_state.intersect_ray(raycast_query)

		if !raycast_collision.is_empty():
			if raycast_collision.normal.is_zero_approx():
				var outward_vector : Vector3 = body.global_position - raycast_collision.collider.global_position
				if outward_vector.is_zero_approx():
					outward_vector = Vector3(randf_range(-1.0, 0.0), 0.0, randf_range(-1.0, 0.0))
				outward_vector.y = 0.0
				__direction = outward_vector
				
			elif raycast_collision.normal.angle_to(Vector3.UP) > max_climb_slope:
				__direction = __direction.slide(raycast_collision.normal)

		var new_velocity = velocity.lerp(__direction.normalized() * speed, delta * speed)

		velocity.x = new_velocity.x
		velocity.z = new_velocity.z

	## Ground raycast

	var ground_raycast_query = PhysicsRayQueryParameters3D.create(
		body.global_position + Vector3.UP,
		body.global_position + Vector3.DOWN * 2.0,
		1 # World
	)
	ground_raycast_query.hit_from_inside = true

	var ground_raycast_collision = get_world_3d().direct_space_state.intersect_ray(ground_raycast_query)

	if ground_raycast_collision.is_empty():
		velocity.y -= 9.8 * delta
	else:
		if ground_raycast_collision.normal.is_zero_approx():
			velocity.y = 0.0
		else:
			velocity.y = (ground_raycast_collision.position.y - body.global_position.y) * speed * 2.0

func _get_look_cone_direction(direction : Vector3, spread : float) -> Vector3:
	var twist : float = randf_range(0, TAU)
	var axis : Vector3 = Vector3(cos(twist), sin(twist), 0)
  
	var angle : float = randf() * spread
	
	var rotation_basis = Basis.looking_at(direction)
  
	return -rotation_basis.z.rotated((rotation_basis * axis).normalized(), angle)
