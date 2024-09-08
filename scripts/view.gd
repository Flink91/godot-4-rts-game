extends Node3D

const MOVE_MARGIN = 20
const MOVE_SPEED = 15 

var camera_position:Vector3
var camera_rotation:Vector3
var mouse_pos = Vector2()

var mouse_sensitivity: float = 0.1
var camera_rotation_y: float = 0


@onready var camera = $Camera

func _ready():
	
	camera_rotation = rotation_degrees # Initial rotation
	
	pass
	
func _input(event):
	
	const FOV_MIN = 15.0
	const FOV_MAX = 65.0
	
	if event.is_action_pressed("wheel_down"):
		camera.fov = lerp(camera.fov, FOV_MAX, 0.25)
	elif event.is_action_pressed("wheel_up"):
		camera.fov = lerp(camera.fov, FOV_MIN, 0.25)
	
	# Rotate camera using mouse (hold 'middle' mouse button)
	if event is InputEventMouseMotion:
		if Input.is_action_pressed("camera_rotate"):
			camera_rotation_y -= event.relative.x * mouse_sensitivity
			#camera_rotation += Vector3(0, -event.relative.x / 10, 0)
			rotation_degrees.y = camera_rotation_y

func _process(delta):
	
	# Set position and rotation to targets
	
	handle_input(delta)
	camera_movement(mouse_pos, delta)

# Handle WASD input
func handle_input(_delta):
	
	# Rotation
	var input := Vector3.ZERO
	
	input.x = Input.get_axis("camera_left", "camera_right")
	input.z = Input.get_axis("camera_forward", "camera_back")
	
	input = input.rotated(Vector3.UP, rotation.y).normalized()
	
	camera_position += input / 4
	# Back to center
	
	if Input.is_action_pressed("camera_center"):
		camera_position = Vector3()
			
func camera_movement(m_pos, delta):
	var viewport_size: Vector2 = get_viewport().size
	var move_vec := Vector3()

	# Define constants for boundaries
	const X_MIN = -100
	const X_MAX = 100
	const Z_MIN = -100
	const Z_MAX = 100

	# Keyboard input handling with smoother diagonal movement
	move_vec.x = Input.get_action_strength("camera_right") - Input.get_action_strength("camera_left")
	move_vec.z = Input.get_action_strength("camera_back") - Input.get_action_strength("camera_forward")

	# Mouse position based movement (near viewport edges)
	if m_pos.x < MOVE_MARGIN and global_transform.origin.x > X_MIN:
		move_vec.x -= 0
	if m_pos.x > viewport_size.x - MOVE_MARGIN and global_transform.origin.x < X_MAX:
		move_vec.x += 1
	if m_pos.y < MOVE_MARGIN and global_transform.origin.z > Z_MIN:
		move_vec.z -= 0
	if m_pos.y > viewport_size.y - MOVE_MARGIN and global_transform.origin.z < Z_MAX:
		move_vec.z += 1

	# Apply movement if any direction is pressed
	if move_vec.length() > 0:
		move_vec = move_vec.normalized().rotated(Vector3(0, 1, 0), rotation.y)
		global_translate(move_vec * delta * MOVE_SPEED)
