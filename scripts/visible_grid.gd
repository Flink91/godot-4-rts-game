extends MeshInstance3D

# Reference to the material with the shader
@export var shader_material: ShaderMaterial

func _process(delta):
	# Get the mouse position in screen space
	var mouse_pos = get_viewport().get_mouse_position()

	# Get the screen size
	var screen_size = get_viewport().size

	# Convert the mouse position to normalized UV space (0.0 to 1.0 range)
	#get_material().set_shader_param("mouse_position", mouse)

	# Update the mouse position in the shader
	print(mouse_pos)
	#shader_material.set_shader_parameter("mouse_pos", normalized_mouse_pos)
