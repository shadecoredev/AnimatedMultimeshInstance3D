extends MultiMeshInstance3D
class_name StaticMultimeshInstance3D

@export var source_multimesh : AnimatedMultiMeshInstance3D

var _buffer_state : PackedFloat32Array = []
var _pool : Array[int] = []

func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	
	multimesh.mesh = source_multimesh.multimesh.mesh
	material_override.set_shader_parameter("total_frame_count", source_multimesh.material_override.get_shader_parameter("total_frame_count"))
	material_override.set_shader_parameter("total_vertex_count", source_multimesh.material_override.get_shader_parameter("total_vertex_count"))
	material_override.set_shader_parameter("albedo", source_multimesh.material_override.get_shader_parameter("albedo"))
	material_override.set_shader_parameter("vertex_animation", source_multimesh.material_override.get_shader_parameter("vertex_animation"))
	material_override.set_shader_parameter("normal_animation", source_multimesh.material_override.get_shader_parameter("normal_animation"))

func add_instance(input_transform : Transform3D, animation_frame : float):
	var index : int

	if !_pool.is_empty():
		index = _pool.pop_back()
		return index
	else:
		multimesh.instance_count += 1
		index = multimesh.instance_count - 1
		_buffer_state.resize(multimesh.instance_count * 16)

	_buffer_state.set(index * 16 + 12,	animation_frame)
	_buffer_state.set(index * 16 + 13,	0.0)
	_buffer_state.set(index * 16 + 14,	0.0)
	_buffer_state.set(index * 16 + 15,	0.0)

	update_transform(index, input_transform)

	multimesh.set_buffer(_buffer_state)

func remove_instance(instance : int) -> void:
	_pool.append(instance)
	instance *= 16
	_buffer_state.set(instance,			0.0)
	_buffer_state.set(instance + 1,		0.0)
	_buffer_state.set(instance + 2,		0.0)
	_buffer_state.set(instance + 3,		0.0)
	_buffer_state.set(instance + 4,		0.0)
	_buffer_state.set(instance + 5,		-100000.0)
	_buffer_state.set(instance + 6,		0.0)
	_buffer_state.set(instance + 7,		0.0)
	_buffer_state.set(instance + 8,		0.0)
	_buffer_state.set(instance + 9,		0.0)
	_buffer_state.set(instance + 10,	0.0)
	_buffer_state.set(instance + 11,	0.0)

func update_transform(instance : int, input_transform : Transform3D) -> void:
	# https://github.com/godotengine/godot/blob/master/servers/rendering/storage/mesh_storage.cpp#L82

	instance *= 16
	_buffer_state.set(instance,			input_transform.basis.x.x)
	_buffer_state.set(instance + 1,		input_transform.basis.x.y)
	_buffer_state.set(instance + 2,		input_transform.basis.x.z)
	_buffer_state.set(instance + 3,		input_transform.origin.x)
	_buffer_state.set(instance + 4,		input_transform.basis.y.x)
	_buffer_state.set(instance + 5,		input_transform.basis.y.y)
	_buffer_state.set(instance + 6,		input_transform.basis.y.z)
	_buffer_state.set(instance + 7,		input_transform.origin.y)
	_buffer_state.set(instance + 8,		input_transform.basis.z.x)
	_buffer_state.set(instance + 9,		input_transform.basis.z.y)
	_buffer_state.set(instance + 10,	input_transform.basis.z.z)
	_buffer_state.set(instance + 11,	input_transform.origin.z)
