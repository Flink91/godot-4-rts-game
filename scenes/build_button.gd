extends Button

func _ready():
    text = "Build Mode Enabled" # Update the text of this button
    toggle_mode = true # Enable toggle mode
    toggled.connect(self._button_toggled) # Connect the toggled signal to the function

func _button_toggled(toggled_on: bool):
    emit_signal("build_mode_toggled", toggled_on)
    if toggled_on:
        text = "Build Mode Enabled" # Update the text of this button
    else:
        text = "Build Mode Disabled" # Update the text of this button

func _input(event: InputEvent) -> void:
     if Input.is_action_just_pressed("build_mode"):
        print("Build mode toggled")
        set_pressed(not is_pressed())