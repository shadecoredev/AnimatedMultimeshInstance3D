@tool
@icon("res://addons/animated_multimeshinstance3d/icons/MultiMeshInstance3D.svg")
extends MultiMeshInstance3D
class_name AnimatedMultiMeshInstance3D
## MultimeshInstance3D that can bake and play animations.

const ANIMATION_SHADER_PATH = "res://addons/animated_multimeshinstance3d/shaders/vetex_animation_shader.gdshader"

const VERTEX_COUNT_LIMIT : int = 8192
const FRAME_COUNT_LIMIT : int = 8192

## Frames per second at which the animation will be baked at. The lower you can set it without animation artifacts, the better.
@export_range(1.0, 30.0, 1.0) var sampling_fps : float = 5.0

## PackedScene containing AnimationPlayer, Skeleton3D and MeshInstance3D.
@export var packed_animation : PackedScene : 
	set(value):
		packed_animation = value
		_clear()
		animation_list.clear()
		notify_property_list_changed()

## Bake the animation.
@export_tool_button("Bake") var bake_tool = _bake

## Disable to store animations into the same directory as the packed animation.
## Enable to set the directory where the baked animation will be stored.
@export var custom_output_directory : bool = false : 
	set(value):
		custom_output_directory = value
		notify_property_list_changed()

## Path to the directory where the baked animation will be stored.
var output_directory: String = "":
	set(value):
		output_directory = value
		DirAccess.open(output_directory)
		if DirAccess.get_open_error() != Error.OK:
			push_warning("Output directory path \"%s\" is invalid." % output_directory)

## Path to the AnimationPlayer within packed animation.
var animation_player_path : String = "AnimationPlayer"

## Path to the MeshInstance3D within packed animation.
var mesh_instance_path : String = "Armature/Skeleton3D/Mesh"

var _rollover_value : float = ProjectSettings.get_setting("rendering/limits/time/time_rollover_secs")
var _is_renderer_forward_plus : bool = RenderingServer.get_current_rendering_method() == "forward_plus"

var _valid_output_directory : String = ""
var _is_baking : bool = false
var _animation_scene : Node3D = null

var _animation_player : AnimationPlayer = null
var _mesh_instance : MeshInstance3D = null
var _mesh : ArrayMesh = null

var _total_num_frames : int = 0
var _total_num_vertices : int = 0
var _mesh_data_tool : MeshDataTool = null

var _vertex_image : Image = null
var _normal_image : Image = null

var _current_animation_index : int = 0
var _current_frame_index : int = 0
var _current_anmiation_frame_count : int = 0
var _total_frame_counter : int = 0

## Dictionary containing the animation data. Manual editing is not recommended. Rebake the animation to update the values.
@export var animation_list : Dictionary[String, MultimeshAnimationData] = {}

func _get_property_list():
	if !Engine.is_editor_hint():
		return

	var property_list = []
	if custom_output_directory:
		property_list.append({
			"name": "output_directory",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_DIR,
			"hint_string": "Path to the directory where the baked animation will be stored."
		 })
	if packed_animation != null:
		property_list.append({
			"name": "Packed Animation Properties",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_CATEGORY,
		 })
		property_list.append({
			"name": "animation_player_path",
			"type": TYPE_STRING,
			"hint_string": "Path to the AnimationPlayer within packed animation."
		 })
		property_list.append({
			"name": "mesh_instance_path",
			"type": TYPE_STRING,
			"hint_string": "Path to the MeshInstance3D within packed animation."
		 })
		
	return property_list

func _ready() -> void:
	_rollover_value = ProjectSettings.get_setting("rendering/limits/time/time_rollover_secs")
	_is_renderer_forward_plus = RenderingServer.get_current_rendering_method() == "forward_plus"

func _process(delta : float) -> void:
	if Engine.is_editor_hint():
		_editor_process(delta)

func _editor_process(delta : float) -> void:
	if !_is_baking:
		return
	
	_mesh_data_tool.create_from_surface(_mesh_instance.bake_mesh_from_current_skeleton_pose(), 0)

	for i in range(_total_num_vertices):
		var vertex = _mesh_data_tool.get_vertex(i)
		_vertex_image.set_pixel(_total_frame_counter, i, Color(vertex.x, vertex.y, vertex.z))
		
		var normal = _mesh_data_tool.get_vertex_normal(i)
		_normal_image.set_pixel(_total_frame_counter, i, Color(normal.x, normal.y, normal.z))
		
	_animation_player.advance(1.0/sampling_fps)

	_current_frame_index += 1
	_total_frame_counter += 1
	
	if _current_frame_index >= _current_anmiation_frame_count:
		_current_animation_index += 1
		
		if _current_animation_index >= _animation_player.get_animation_list().size():
			_is_baking = false
			_save_animation()
			_clear()
		else:
			_update_new_animation()

		_current_frame_index = 0

func _save_animation() -> void:
	var error_vertex = ResourceSaver.save(_vertex_image, _valid_output_directory + "/vertex_animation.tres")
	if error_vertex != Error.OK:
		printerr("Error while saving vertex animation to %s" % _valid_output_directory + "/vertex_animation.tres")
		return
		
	var error_normal = ResourceSaver.save(_normal_image, _valid_output_directory + "/normal_animation.tres")
	if error_normal != Error.OK:
		printerr("Error while saving normal animation to %s" % _valid_output_directory + "/normal_animation.tres")
		return
	
	var vertex_animation_shader_material = ShaderMaterial.new()
	vertex_animation_shader_material.set_shader(load(ANIMATION_SHADER_PATH))
	vertex_animation_shader_material.set_shader_parameter("vertex_animation", 
		ImageTexture.create_from_image(
			ResourceLoader.load(
				_valid_output_directory + "/vertex_animation.tres"
			)
		)
	)
	vertex_animation_shader_material.set_shader_parameter("normal_animation",
		ImageTexture.create_from_image(
			ResourceLoader.load(
				_valid_output_directory + "/normal_animation.tres"
			)
		)
	)
	vertex_animation_shader_material.set_shader_parameter("total_frame_count", float(_total_frame_counter))
	vertex_animation_shader_material.set_shader_parameter("total_vertex_count", float(_total_num_vertices))
	vertex_animation_shader_material.set_shader_parameter("sampling_fps", sampling_fps)
		
	ResourceSaver.save(vertex_animation_shader_material, _valid_output_directory + "/animation_material.tres")

	material_override = ResourceLoader.load(_valid_output_directory + "/animation_material.tres")

func _get_output_directory() -> DirAccess:
	var output_diraccess : DirAccess = null
	if custom_output_directory:
		output_diraccess = DirAccess.open(output_directory)
	else:
		var packed_scene_path = packed_animation.resource_path.rstrip(
			packed_animation.resource_path.get_file()
		)
		output_diraccess = DirAccess.open(packed_scene_path)
	return output_diraccess

func _clear() -> void:
	if _animation_scene != null:
		_animation_scene.queue_free()
		_animation_scene = null
		
	_animation_player = null
	_mesh_instance = null
	_mesh = null

	_total_num_frames = 0
	_total_num_vertices = 0
	_mesh_data_tool = null

	_vertex_image = null
	_normal_image = null

	_current_animation_index = 0
	_current_frame_index = 0
	_current_anmiation_frame_count = 0
	_total_frame_counter = 0

	_current_anmiation_frame_count = 0
	_current_animation_index = 0
	_current_frame_index = 0

func _bake() -> void:
	if packed_animation == null:
		printerr("PackedAnimation is invalid.")
		return

	var output_diraccess : DirAccess = _get_output_directory()
		
	if output_diraccess == null:
		printerr("Output directory path is invalid.")
		return
		
	_clear()
	
	if _animation_scene == null:
		_animation_scene = packed_animation.instantiate()
		add_child(_animation_scene)
		_animation_scene.set_owner(get_tree().edited_scene_root)
		_animation_scene.name = "Baker"
	
	_animation_player = _animation_scene.get_node_or_null(animation_player_path) as AnimationPlayer
	if _animation_player == null:
		printerr(
			("AnmiationPlayer not found in the packed animation at the path \"%s\". " % animation_player_path) + 
			"Change the packed animation properties."
		)
		return

	_mesh_instance = _animation_scene.get_node_or_null(mesh_instance_path) as MeshInstance3D
	if _mesh_instance == null:
		printerr(
			("MeshInstance3D not found in the packed animation at the path \"%s\". " % mesh_instance_path) +
			"Change the packed animation properties."
		)
		return

	_valid_output_directory = output_diraccess.get_current_dir()

	if _animation_player.get_animation_list().is_empty():
		printerr("Packed animation doesn't contain any animations.")
		return

	print("Detected %d animations." % _animation_player.get_animation_list().size())

	_total_num_frames = 0
	for animation_name in _animation_player.get_animation_list():
		var animation : Animation = _animation_player.get_animation(animation_name)
		_total_num_frames += max(ceil(animation.length * sampling_fps), 1)

	print("Detected %d frames." % _total_num_frames)

	if _total_num_frames > FRAME_COUNT_LIMIT:
		printerr(
			("Total amount of frames exceeded the limit of %d. " % FRAME_COUNT_LIMIT) +
		 	"Lower the sampling FPS to reduce frame count."
		)
		return

	_mesh = _mesh_instance.mesh as ArrayMesh

	_mesh_data_tool = MeshDataTool.new()
	_mesh_data_tool.create_from_surface(_mesh, 0)
	_total_num_vertices = _mesh_data_tool.get_vertex_count()
	print("Detected %d vertices." % _total_num_vertices)
	
	if _total_num_vertices > VERTEX_COUNT_LIMIT:
		printerr(
			("Total amount of vertices exceeded the limit of %d. " % VERTEX_COUNT_LIMIT) + 
			"Lower the amount of vertices in your model using external tools."
		)
		return

	_vertex_image = Image.create_empty(_total_num_frames, _total_num_vertices, false, Image.FORMAT_RGBF)
	_normal_image = Image.create_empty(_total_num_frames, _total_num_vertices, false, Image.FORMAT_RGBF)

	animation_list.clear()

	_update_new_animation()

	_initialize_multimesh()
	
	_start_baking.call_deferred()

func _start_baking() -> void:
	_is_baking = true

func _update_new_animation() -> void:
	_current_anmiation_frame_count = max(
		ceil(
			_animation_player.get_animation(
				_animation_player.get_animation_list()[_current_animation_index]
			).length * sampling_fps
		),
		1
	)
	
	var current_animation_name = _animation_player.get_animation_list()[_current_animation_index]
	animation_list[current_animation_name] = \
		MultimeshAnimationData.new().set_values(
			_total_frame_counter,
			_current_anmiation_frame_count
		)
	print("Added anmiation \"%s\" to the animation list." % current_animation_name)
			
	var animation_name = _animation_player.get_animation_list()[_current_animation_index]
	_animation_player.play(animation_name)
	_animation_player.advance(1.0/sampling_fps)

func _initialize_multimesh() -> void:
	if multimesh == null:
		multimesh = MultiMesh.new()
		
	if !multimesh.use_custom_data:
		multimesh.instance_count = 0
		multimesh.use_custom_data = true
	
	if multimesh.transform_format != MultiMesh.TRANSFORM_3D:
		multimesh.instance_count = 0
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
	
	multimesh.mesh = _mesh

## Returns the list of stored animation keys.
func get_animation_list() -> Array[String]:
	return animation_list.keys()

## Plays the animation from animation list for a specific instance.
func play(
	instance : int,
	animation_name: StringName = &"",
	blend_time : float = 1.0):
	if !animation_list.has(animation_name):
		push_warning("Animation with name \"%s\" not found." % animation_name)
		return
		
	var current_animation : MultimeshAnimationData = null

	if _is_renderer_forward_plus:
		current_animation = _get_animation(instance)
	
	var animation : MultimeshAnimationData = animation_list[animation_name]

	multimesh.set_instance_custom_data(instance, _combine_custom_buffer(current_animation, animation, blend_time))

## Plays the animation from animation from data for a specific instance.
func play_custom(
	instance : int,
	animation : MultimeshAnimationData,
	blend_time : float = 0.0
):
	var current_animation : MultimeshAnimationData = null

	if _is_renderer_forward_plus:
		current_animation = _get_animation(instance)
	
	multimesh.set_instance_custom_data(instance, _combine_custom_buffer(current_animation, animation, blend_time))

func _get_animation(instance : int) -> MultimeshAnimationData:
	return MultimeshAnimationData.dencode_forward_plus(
		multimesh.get_instance_custom_data(instance).g
	)

func _combine_custom_buffer(
	main_animation : MultimeshAnimationData,
	blended_animation : MultimeshAnimationData = main_animation,
	blend_time : float = 0.0
):
	if _is_renderer_forward_plus:
		var blend_timestamp : float = fmod((float(Time.get_ticks_msec()) / 1000.0), _rollover_value) - 1.0
		return Color(
			MultimeshAnimationData.encode_forward_plus(main_animation),
			MultimeshAnimationData.encode_forward_plus(blended_animation),
			blend_timestamp,
			blend_time
		)
	else:
		return Color(
			MultimeshAnimationData.encode_compatibility(blended_animation.start_frame),
			MultimeshAnimationData.encode_compatibility(blended_animation.length),
			0.0,
			0.0
		)
