extends Control

# Called every frame. Update the label with the current mouse position relative to this control.
func _process(_delta: float) -> void:
	# Get the local mouse position relative to this control
	var viewport_size = get_viewport_rect().size
	var mouse_pos = get_viewport().get_mouse_position()
	var local_mouse_pos = get_local_mouse_position()
	var normalized_mouse_pos = mouse_pos / viewport_size
	
	# Get the Label node (assuming the Label is a child of this node)
	var label = $Label
	
	# Update the label text with the relative mouse position
	label.text = "Mouse Position local: " + str(local_mouse_pos)
	label.text += "\n"
	label.text += "Mouse Position: " + str(mouse_pos)
	label.text += "\n"
	label.text += "Mouse Position normalized: " + str(normalized_mouse_pos)
	label.text += "\n"
