extends MeshInstance3D

# Reference to the material with the shader
@export var shader_material: ShaderMaterial

func _process(_delta):
    pass

func _on_button_toggled(is_active: bool) -> void:
    visible = is_active
