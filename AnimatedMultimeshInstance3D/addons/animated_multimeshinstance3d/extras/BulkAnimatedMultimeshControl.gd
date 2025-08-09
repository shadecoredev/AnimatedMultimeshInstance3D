@tool
extends Node
class_name BulkAnimatedMultimeshControl

## AnimatedMultiMeshInstance3D that will be updated.
@export var target_animated_multimesh : AnimatedMultiMeshInstance3D

## Amount of instances to spawn.
@export var target_instance_count : int = 1000;

## Random scale range for instances.
@export_range(1.0, 10.0) var random_scale_range : float = 1.15

## Random rotation range for instances.
@export_range(0.0, PI) var rotation_range = PI

## Shape to define volume to spawn multimesh instances.
@export var shape : Shape3D = null

## Set this if you want to play a custom animation. Leave empty to play random animation.
@export var custom_animation : MultimeshAnimationData = null

@export_tool_button("Update") var update_tool = _update

func _ready() -> void:
	_update()

func _update() -> void:
	if target_animated_multimesh.multimesh == null:
		print("multimesh missing")
		return

	target_animated_multimesh.multimesh.instance_count = target_instance_count

	var iter_transform : Transform3D

	for i in range(target_instance_count):
		
		var instance_position = _get_random_instance_position()
		
		iter_transform = Transform3D.IDENTITY \
		.scaled(Vector3.ONE * randf_range(1.0, random_scale_range)) \
		.rotated(Vector3.UP, randf_range(-rotation_range, rotation_range)) \
		.translated(instance_position)
		target_animated_multimesh.multimesh.set_instance_transform(i, iter_transform)

		if custom_animation == null:
			var animation_list = target_animated_multimesh.get_animation_list()
			var animation_name = animation_list.pick_random()
			target_animated_multimesh.play(i, animation_name)
		else:
			target_animated_multimesh.play_custom(i, custom_animation)

func _get_random_instance_position() -> Vector3:
	var random_position = Vector3.ZERO
	
	if shape is BoxShape3D:
		random_position = Vector3(
			randf_range(-shape.size.x, shape.size.x),
			randf_range(-shape.size.y, shape.size.y),
			randf_range(-shape.size.z, shape.size.z)
		)

	elif shape is SphereShape3D:
		random_position = Vector3(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		)
		random_position = random_position.normalized()
		random_position *= (1.0 - randf() * randf()) * shape.radius
	
	elif shape is CylinderShape3D:
		var theta : float = randf() * 2.0 * PI
		var random_inside_circle = Vector2(cos(theta), sin(theta)) * sqrt(randf())
		random_position.y = randf_range(-shape.height, shape.height)
		random_position.x = random_inside_circle.x * shape.radius
		random_position.z = random_inside_circle.y * shape.radius

	else:
		printerr("Shape not supported. Use BoxShape3D, SphereShape3D or CylinderShape3D.")
	
	return random_position
