extends Node
class_name ShootGun

const NUM_RAYCASTS : int = 7

@export_category("Nodes")
@export var source : CharacterBody3D
@export var hand : Node3D
@export var bullet_spawn_source : Node3D
@export var exclude_shape : CollisionShape3D

@export var debug_marker : Sprite3D

@export var cooldown : float = 0.5

var _shoot_cooldown = 0.0

func _process(delta):
	if _shoot_cooldown > 0.0:
		_shoot_cooldown -= delta
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_shoot()
		_shoot_cooldown  = cooldown

func _shoot():
	var direction = -bullet_spawn_source.basis.z
	
	var exclude_array : Array[RID] = [source.get_rid()]
	
	for i in range(NUM_RAYCASTS):
		var bullet_raycast_query = PhysicsRayQueryParameters3D.create(
			bullet_spawn_source.global_position,
			bullet_spawn_source.global_position + direction * 500.0,
			5, # World + Enemies
			exclude_array
		)
		bullet_raycast_query.collide_with_areas = true
		bullet_raycast_query.hit_from_inside = true

		var bullet_collision = source.get_world_3d().direct_space_state.intersect_ray(bullet_raycast_query)
		
		if bullet_collision.is_empty():
			break

		if bullet_collision.collider is StaticBody3D:
			Debug.draw_ray(bullet_spawn_source.global_position, bullet_collision.position, Color.RED, 3.0)
			break

		await get_tree().physics_frame

		if bullet_collision.collider is MultimeshInstanceControl:
			var body_part_collision = await bullet_collision.collider.check_physics_collision(bullet_collision.position - direction, direction * 3.0)
			if body_part_collision.is_empty():
				exclude_array.append(bullet_collision.collider.get_rid())
			else:
				Debug.draw_ray(bullet_spawn_source.global_position, bullet_collision.position, Color.GREEN, 3.0)
				apply_hit(bullet_collision.collider, body_part_collision)
				break

func apply_hit(collider, body_part_collision):
	debug_marker.global_position = body_part_collision.position
	collider.apply_damage(1000.0)
