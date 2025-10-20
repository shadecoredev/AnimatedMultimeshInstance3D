extends Node3D
class_name MultimeshInstanceProcessor

@export var label : Label

@export var bulk_control : BulkMultimeshControl
@export var packed_scene : PackedScene

@export var spawn_amount : int = 10

@export var spawn_radius : float = 100.0
@export var random_size : float = 1.15

@export var target : Node3D

var _process_child_count : int = 4096
var _process_current_child_index : int = 0

var _ai_child_count : int = 256
var _ai_current_child_index : int = 0

var _child_count : int = 0

var _elapsed_delta : float = 0.0

func _input(event):
	if event is InputEventKey and event.is_released():
		if event.keycode == KEY_F1:
			_spawn_instances()

func _spawn_instances():
	if spawn_amount == 1:
		var instance = _spawn_instance()
		instance.register(bulk_control)
	else:
		var instance_id_list = bulk_control.bulk_register_instances(spawn_amount)
		for id in instance_id_list:
			var instance = _spawn_instance()
			instance.bulk_register(bulk_control, id)
	
	_child_count += spawn_amount
	
	if label:
		label.text = "Instances: %d" % bulk_control.mmi.multimesh.instance_count

func _spawn_instance() -> MultimeshInstanceControl:
	var instance = packed_scene.instantiate() as MultimeshInstanceControl
	add_child(instance)
	instance.scale = Vector3.ONE * randf_range(1.0, random_size)
	
	var theta : float = randf() * 2.0 * PI
	var random_inside_circle = Vector2(cos(theta), sin(theta)) * sqrt(randf())
	
	instance.position = Vector3(
		random_inside_circle.x * spawn_radius + target.position.x,
		0.0,
		random_inside_circle.y * spawn_radius + target.position.z,
	)
	
	var swarm_movement : SwarmMovement = instance.get_child(0)
	swarm_movement.initialize_delta(_elapsed_delta)
	
	instance.destroy_signal.connect(_destroy_callback)
	
	return instance

func _destroy_callback(_instance : int) -> void:
	_child_count -= 1

func _physics_process(delta):
	_elapsed_delta += delta
	
	if _child_count == 0:
		return

	if _child_count <= _process_child_count:
		for i in range(_child_count):
			get_child(i)._lazy_process(_elapsed_delta)
	else:
		for i in range(_process_child_count):
			_process_current_child_index += 1
			if _process_current_child_index >= _child_count:
				_process_current_child_index -= _child_count
			get_child(_process_current_child_index)._lazy_process(_elapsed_delta)

	if _child_count <= _ai_child_count:
		for i in range(_child_count):
			get_child(i)._ai_process(_elapsed_delta)
	else:
		for i in range(_ai_child_count):
			_ai_current_child_index += 1
			if _ai_current_child_index >= _child_count:
				_ai_current_child_index -= _child_count
			get_child(_ai_current_child_index)._ai_process(_elapsed_delta)
