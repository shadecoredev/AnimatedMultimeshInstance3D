extends Area3D
class_name MultimeshInstanceControl

var _instance_id : int
var _bulk_control : BulkMultimeshControl

var health : float = 100.0

var registered : bool = false

@export var ai : Node3D

signal ai_process_signal
signal lazy_process_signal
signal destroy_signal

func register(bulk_control : BulkMultimeshControl) -> void:
	_bulk_control = bulk_control
	_instance_id = bulk_control.register_instance()
	registered = true

func bulk_register(bulk_control : BulkMultimeshControl, instance_id : int) -> void:
	_bulk_control = bulk_control
	_instance_id = instance_id
	registered = true

func update_transform() -> void:
	if !registered:
		return
	_bulk_control.update_transform(_instance_id, transform)

func _lazy_process(elapsed_delta : float) -> void:
	if !registered:
		return
	lazy_process_signal.emit(elapsed_delta)

func _ai_process(elapsed_delta : float) -> void:
	if !registered:
		return
	ai_process_signal.emit(elapsed_delta)

func destroy() -> void:
	if !registered:
		return

	collision_layer = 0
	collision_mask = 0
	
	registered = false

	_bulk_control.handle_death(self)

func check_physics_collision(ray_start : Vector3, ray_direction : Vector3) -> Dictionary:
	_bulk_control.update_physics_body(_instance_id, global_transform, scale)
	await get_tree().physics_frame
	var raycast_query = PhysicsRayQueryParameters3D.create(
		ray_start,
		ray_start + ray_direction,
		8 # Enemy body collider
	)
	
	return get_world_3d().direct_space_state.intersect_ray(raycast_query)
	
func apply_damage(damage : float):
	health -= damage
	if health <= 0.0:
		destroy()

func play_animation(animation_name : String, blend_time : float):
	_bulk_control.play_animation(_instance_id, animation_name, blend_time)

func get_idle_noise(noise_position : Vector3) -> float:
	return _bulk_control.idle_movement_noise.get_noise_3dv(noise_position)
