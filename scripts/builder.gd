extends Node3D

@export var structures: Array[Structure] = []

var map: DataMap

var index: int = 0 # Index of structure being built

@export var build_mode_button: Button # Reference to the build mode button

@export var selector: Node3D # The 'cursor'
@export var selector_preview_container: Node3D # Node that holds a preview of the structure
@export var view_camera: Camera3D # Used for raycasting mouse
@export var gridmap: GridMap
@export var cash_display: Label

@onready var level_gridmap = $"../Level/GridMap"

var plane: Plane # Used for raycasting mouse

var is_build_mode_active: bool = true

var is_building = false
var is_demolishing = false

func _ready() -> void:
    
    map = DataMap.new()
    plane = Plane(Vector3.UP, Vector3.ZERO)
    
    # Create new MeshLibrary dynamically, can also be done in the editor
    # See: https://docs.godotengine.org/en/stable/tutorials/3d/using_gridmaps.html
    
    var mesh_library = MeshLibrary.new()
    
    for structure in structures:
        
        var id = mesh_library.get_last_unused_item_id()
        
        mesh_library.create_item(id)
        mesh_library.set_item_mesh(id, get_mesh(structure.model))
        mesh_library.set_item_mesh_transform(id, Transform3D())
        
    gridmap.mesh_library = mesh_library
    
    update_structure()
    update_cash()

func _process(delta):
    if not is_build_mode_active:
        visible = false
        return
    else:
        visible = true

    # Map position based on mouse
    var world_position = plane.intersects_ray(
        view_camera.project_ray_origin(get_viewport().get_mouse_position()),
        view_camera.project_ray_normal(get_viewport().get_mouse_position()))

    if world_position != null:
        var gridmap_position = Vector3(round(world_position.x), 0, round(world_position.z))
        selector.position = lerp(selector.position, gridmap_position, delta * 40)

        # Perform build or demolish if dragging
        if is_building:
            action_build(gridmap_position)
        if is_demolishing:
            action_demolish(gridmap_position)

func _unhandled_input(event):
    # Start building when mouse button is pressed
    if event.is_action_pressed("build"):
        is_building = true
    
    # Stop building when mouse button is released
    if event.is_action_released("build"):
        is_building = false

    # Start demolishing when mouse button is pressed
    if event.is_action_pressed("demolish"):
        is_demolishing = true
    
    # Stop demolishing when mouse button is released
    if event.is_action_released("demolish"):
        is_demolishing = false

    # Controls for one-time actions like rotate, structure toggle, save, and load
    if event.is_action_pressed("rotate"):
        action_rotate() # Rotates selection 90 degrees

    if event.is_action_pressed("structure_next") or event.is_action_pressed("structure_previous"):
        action_structure_toggle() # Toggles between structures

    if event.is_action_pressed("save"):
        action_save() # Saving

    if event.is_action_pressed("load"):
        action_load() # Loading


# Retrieve the mesh from a PackedScene, used for dynamically creating a MeshLibrary
func get_mesh(packed_scene):
    var scene_state: SceneState = packed_scene.get_state()
    for i in range(scene_state.get_node_count()):
        if (scene_state.get_node_type(i) == "MeshInstance3D"):
            for j in scene_state.get_node_property_count(i):
                var prop_name = scene_state.get_node_property_name(i, j)
                if prop_name == "mesh":
                    var prop_value = scene_state.get_node_property_value(i, j)
                    
                    return prop_value.duplicate()
                    
                    
# Build (place) a structure
func action_build(gridmap_position):
    print(gridmap_position)
    # Check if a block is already at the specified position in the level gridmap y+1
    var level_gridmap_floor_1 = Vector3i(gridmap_position.x, gridmap_position.y + 1, gridmap_position.z)
    var level_gridmap_floor = Vector3i(gridmap_position.x, gridmap_position.y, gridmap_position.z)
    var existing_tile_level = level_gridmap.get_cell_item(level_gridmap_floor_1)
    var existing_tile_level_floor = level_gridmap.get_cell_item(level_gridmap_floor)
    

    var existing_tile_build = gridmap.get_cell_item(gridmap_position)
    if existing_tile_level == -1 and existing_tile_level_floor != -1 and existing_tile_build == -1: # No block in either gridmap at the position
        gridmap.set_cell_item(gridmap_position, index, gridmap.get_orthogonal_index_from_basis(selector.basis))
    
    if existing_tile_build != index:
        map.cash -= structures[index].price
        update_cash()


# Demolish (remove) a structure
func action_demolish(gridmap_position):
    gridmap.set_cell_item(gridmap_position, -1)

# Rotates the 'cursor' 90 degrees

func action_rotate():
    if Input.is_action_just_pressed("rotate"):
        selector.rotate_y(deg_to_rad(90))

# Toggle between structures to build

func action_structure_toggle():
    if Input.is_action_just_pressed("structure_next"):
        index = wrap(index + 1, 0, structures.size())
    
    if Input.is_action_just_pressed("structure_previous"):
        index = wrap(index - 1, 0, structures.size())

    update_structure()

# Update the structure visual in the 'cursor'

func update_structure():
    # Clear previous structure preview in selector
    for n in selector_preview_container.get_children():
        selector_preview_container.remove_child(n)
        
    # Create new structure preview in selector
    var _model = structures[index].model.instantiate()
    selector_preview_container.add_child(_model)
    _model.position.y += 0.25
    
func update_cash():
    cash_display.text = "$" + str(map.cash)

# Saving/load

func action_save():
    if Input.is_action_just_pressed("save"):
        print("Saving map...")
        
        map.structures.clear()
        for cell in gridmap.get_used_cells():
            
            var data_structure: DataStructure = DataStructure.new()
            
            data_structure.position = Vector2i(cell.x, cell.z)
            data_structure.orientation = gridmap.get_cell_item_orientation(cell)
            data_structure.structure = gridmap.get_cell_item(cell)
            
            map.structures.append(data_structure)
            
        ResourceSaver.save(map, "user://map.res")
    
func action_load():
    if Input.is_action_just_pressed("load"):
        print("Loading map...")
        
        gridmap.clear()
        
        map = ResourceLoader.load("user://map.res")
        if not map:
            map = DataMap.new()
        for cell in map.structures:
            gridmap.set_cell_item(Vector3i(cell.position.x, 0, cell.position.y), cell.structure, cell.orientation)
            
        update_cash()


func _on_button_toggled(toggled_on: bool) -> void:
    is_build_mode_active = toggled_on
