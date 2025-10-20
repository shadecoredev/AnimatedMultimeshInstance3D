extends Node
class_name BulkMultimeshControl

@export var mmi : AnimatedMultiMeshInstance3D

#var _instance_transform_previous_state : PackedFloat32Array
var _buffer_state : PackedFloat32Array

var _pool : Array[int] = []

@export var physics_body : PhysicalBoneSimulator3D

@export var physics_body_root : Node3D
@export var physics_body_parent_path : String
@export var animation_player_path : String
@export var mesh_path : String

@export var idle_movement_noise : FastNoiseLite

@export var static_multimesh : StaticMultimeshInstance3D

var animation_player : AnimationPlayer

@export var animation_list : Array[String] = []

var _animation_data : Array[MultimeshAnimationData] = []
var _animation_count : int = 0

var death_animation_variants : PackedStringArray = [
	"Death",
	"Death2"
]

func _ready() -> void:
	call_deferred("_setup_physics_body")
	animation_player = physics_body_root.get_node(animation_player_path)
	
	var mesh = physics_body_root.get_node(mesh_path)
	if mesh != null and mesh is MeshInstance3D:
		mesh.visible = false

	for animation_name in animation_list:
		var data = mmi.get_animation_data(animation_name)
		_animation_data.append(data)
		_animation_count += 1
	
	_buffer_state = PackedFloat32Array()
	
	#physics_body.physical_bones_start_simulation()

func _setup_physics_body():
	physics_body.reparent(physics_body_root.get_node(physics_body_parent_path))

func unregister_instance(instance : int) -> void:
	_pool.append(instance)
	instance *= 16
	_buffer_state.set(instance,			0.0)
	_buffer_state.set(instance + 1,		0.0)
	_buffer_state.set(instance + 2,		0.0)
	_buffer_state.set(instance + 3,		0.0)
	_buffer_state.set(instance + 4,		0.0)
	_buffer_state.set(instance + 5,		-10000.0)
	_buffer_state.set(instance + 6,		0.0)
	_buffer_state.set(instance + 7,		0.0)
	_buffer_state.set(instance + 8,		0.0)
	_buffer_state.set(instance + 9,		0.0)
	_buffer_state.set(instance + 10,	0.0)
	_buffer_state.set(instance + 11,	0.0)

func register_instance() -> int:
	var index : int
	
	var random_animation_id = randi_range(0, _animation_count - 1)
	var custom_data = mmi.combine_custom_buffer(
		_animation_data[random_animation_id],
		_animation_data[random_animation_id]
	)
	
	if !_pool.is_empty():
		index = _pool.pop_back()
		_buffer_state.set(index * 16 + 12,	custom_data.r)
		_buffer_state.set(index * 16 + 13,	custom_data.g)
		_buffer_state.set(index * 16 + 14,	custom_data.b)
		_buffer_state.set(index * 16 + 15,	custom_data.a)

		reset_transform(index)

		return index

	
	mmi.multimesh.instance_count += 1
	index = mmi.multimesh.instance_count - 1
	_buffer_state.resize(mmi.multimesh.instance_count * 16)
	_buffer_state.set(index * 16 + 12,	custom_data.r)
	_buffer_state.set(index * 16 + 13,	custom_data.g)
	_buffer_state.set(index * 16 + 14,	custom_data.b)
	_buffer_state.set(index * 16 + 15,	custom_data.a)
	
	reset_transform(index)

	#mmi.multimesh.reset_instance_physics_interpolation(mmi.multimesh.instance_count - 1)


	#_instance_transform_previous_state.resize(mmi.multimesh.instance_count * 16)


	reset_physics_interpolation()
	return index

func bulk_register_instances(amount : int) -> PackedInt32Array:
	var output = PackedInt32Array()
	output.resize(amount)
	
	var index : int

	while (!_pool.is_empty()) and amount > 0:
		var random_animation_id = randi_range(0, _animation_count - 1)
		var custom_data = mmi.combine_custom_buffer(
			_animation_data[random_animation_id],
			_animation_data[random_animation_id]
		)
		index = _pool.pop_back()
		_buffer_state.set(index * 16 + 12,	custom_data.r)
		_buffer_state.set(index * 16 + 13,	custom_data.g)
		_buffer_state.set(index * 16 + 14,	custom_data.b)
		_buffer_state.set(index * 16 + 15,	custom_data.a)
		reset_transform(index)
		output[amount - 1] = index
		amount -= 1
	
	mmi.multimesh.instance_count += amount
	_buffer_state.resize(mmi.multimesh.instance_count * 16)
	for i in range(amount):
		#mmi.multimesh.reset_instance_physics_interpolation(mmi.multimesh.instance_count - i - 1)
		index = mmi.multimesh.instance_count - i - 1
		
		var random_animation_id = randi_range(0, _animation_count - 1)
		var custom_data = mmi.combine_custom_buffer(
			_animation_data[random_animation_id],
			_animation_data[random_animation_id]
		)

		_buffer_state.set(index * 16 + 12,	custom_data.r)
		_buffer_state.set(index * 16 + 13,	custom_data.g)
		_buffer_state.set(index * 16 + 14,	custom_data.b)
		_buffer_state.set(index * 16 + 15,	custom_data.a)
		reset_transform(index)
		output[i] = index
	
	reset_physics_interpolation()
	return output

func reset_transform(instance) -> void:
	instance *= 16
	_buffer_state.set(instance,			1.0)
	_buffer_state.set(instance + 1,		0.0)
	_buffer_state.set(instance + 2,		0.0)
	_buffer_state.set(instance + 3,		0.0)
	_buffer_state.set(instance + 4,		0.0)
	_buffer_state.set(instance + 5,		1.0)
	_buffer_state.set(instance + 6,		0.0)
	_buffer_state.set(instance + 7,		0.0)
	_buffer_state.set(instance + 8,		0.0)
	_buffer_state.set(instance + 9,		0.0)
	_buffer_state.set(instance + 10,	1.0)
	_buffer_state.set(instance + 11,	0.0)

func update_transform(instance : int, transform : Transform3D) -> void:
	# https://github.com/godotengine/godot/blob/master/servers/rendering/storage/mesh_storage.cpp#L82
	
	instance *= 16
	_buffer_state.set(instance,			transform.basis.x.x)
	_buffer_state.set(instance + 1,		transform.basis.x.y)
	_buffer_state.set(instance + 2,		transform.basis.x.z)
	_buffer_state.set(instance + 3,		transform.origin.x)
	_buffer_state.set(instance + 4,		transform.basis.y.x)
	_buffer_state.set(instance + 5,		transform.basis.y.y)
	_buffer_state.set(instance + 6,		transform.basis.y.z)
	_buffer_state.set(instance + 7,		transform.origin.y)
	_buffer_state.set(instance + 8,		transform.basis.z.x)
	_buffer_state.set(instance + 9,		transform.basis.z.y)
	_buffer_state.set(instance + 10,	transform.basis.z.z)
	_buffer_state.set(instance + 11,	transform.origin.z)

func _physics_process(_delta):
	mmi.multimesh.set_buffer(_buffer_state)

func update_physics_body(instance : int, transform : Transform3D, scale : Vector3):
	physics_body_root.transform = Transform3D.IDENTITY\
			.rotated(
				Vector3.UP,
				transform.basis.x.signed_angle_to(
					Vector3.RIGHT,
					Vector3.UP
				) + PI
			)\
			.scaled(
				scale
			)\
			.translated(
				transform.origin
			)

	var animation_name : String = mmi.get_current_animation_name(instance)
	animation_player.play(animation_name, -1.0, 0.0)
	var timestamp : float = mmi.get_current_timestamp() - float(instance) * 0.19 # + float(iteration) * get_physics_process_delta_time()
	#animation_player.play_section(animation_name, timestamp, timestamp, -1.0, 1.0)
	animation_player.seek(timestamp, true)

func play_animation(instance : int, animation_name : String, blend_duration : float, blend_out_time : float = 0.0):
	var current_animation = mmi.get_animation(instance)
	var animation_data = mmi.get_animation_data(animation_name)
	
	var custom_data = mmi.combine_custom_buffer(
		current_animation,
		animation_data,
		blend_duration,
		blend_out_time
	)

	_buffer_state.set(instance * 16 + 12,	custom_data.r)
	_buffer_state.set(instance * 16 + 13,	custom_data.g)
	_buffer_state.set(instance * 16 + 14,	custom_data.b)
	_buffer_state.set(instance * 16 + 15,	custom_data.a)

func add_corpse(input_transform : Transform3D, frame : float):
	static_multimesh.add_instance(
		input_transform,
		frame
	)

func handle_death(instance : MultimeshInstanceControl):
	
	var death_animation_name = death_animation_variants[randi_range(0, death_animation_variants.size() - 1)]
	var animation_data = mmi.get_animation_data(death_animation_name)
	var frame : float = float(animation_data.start_frame + animation_data.length - 1)

	play_animation(instance._instance_id, death_animation_name, 0.3, 10.0)

	create_tween().tween_callback(
		func():
			unregister_instance(instance._instance_id)
			add_corpse(instance.transform, frame + 0.5)
			instance.destroy_signal.emit(instance._instance_id)
			instance.queue_free()
	).set_delay((animation_data.length - 1) / mmi.sampling_fps)
