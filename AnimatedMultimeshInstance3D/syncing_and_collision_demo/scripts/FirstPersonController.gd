extends CharacterBody3D
class_name FirstPersonController

@export_category("Startup")
## Capture mouse on ready.
@export var startup_capture_mouse : bool = false

@export_category("Parameters")
@export_group("Camera")
## Camera rotation multiplier.
@export var view_rotation_sensitivity : float = 0.1
## Camera position lerping toward head position multiplier.
@export var camera_lerping : float = 1.0

@export_group("Walking")
@export var base_speed : float = 4.317
@export_group("Jumping")
@export var base_jump_velocity : float = 5.0

@export_group("Acceleration")
@export var gravity : float = 9.8
@export_category("Setup")

@export_group("Nodes")
@export var COLLIDER : CollisionShape3D = null
@export var HEAD : Node3D = null
@export var HEAD_ROOT : Node3D = null
@export var CAMERA : Camera3D = null

@export_group("Controls")
@export var JUMP : StringName = &"ui_select"
@export var LEFT : StringName = &"ui_left"
@export var RIGHT : StringName = &"ui_right"
@export var FORWARD : StringName = &"ui_up"
@export var BACKWARD : StringName = &"ui_down"

func _ready() -> void:
	CAMERA.top_level = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta) -> void:
	CAMERA.position = CAMERA.position.lerp(HEAD_ROOT.global_position, clampf(camera_lerping * delta / get_physics_process_delta_time(), 0.0, 1.0))
	CAMERA.rotation = HEAD_ROOT.global_rotation
	

func _physics_process(delta) -> void:
	_handle_movement(delta, Input.get_vector(LEFT, RIGHT, FORWARD, BACKWARD))

func _handle_movement(delta, direction) -> void:
	direction = direction.rotated(-rotation.y)

	velocity.x = lerp(velocity.x, direction.x * base_speed, delta * 10.0)
	velocity.y = (velocity.y - gravity * delta) * float(!is_on_floor() or velocity.y > 0.0)
	velocity.z = lerp(velocity.z, direction.y * base_speed, delta * 10.0)

	move_and_slide()

func _unhandled_input(event) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		HEAD.rotation_degrees.x -= event.relative.y * view_rotation_sensitivity
		
		HEAD.rotation.x = clamp(HEAD.rotation.x, deg_to_rad(-90), deg_to_rad(90))
		
		rotation_degrees.y -= event.relative.x * view_rotation_sensitivity
	

func _unhandled_key_input(event) -> void:
	if event.is_pressed():
		if event.is_action(JUMP) and is_on_floor():
			velocity.y = base_jump_velocity

		elif event.keycode == KEY_ESCAPE:
			get_tree().quit()
