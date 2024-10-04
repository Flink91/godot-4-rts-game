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

var is_build_mode_active: bool = true

var is_building = false
var is_demolishing = false

var grid_cell_size = Vector3(1, 1, 1) # Size of one grid cell (adjust if needed)
	
func _ready() -> void:
	
	map = DataMap.new()
	
	# Create new MeshLibrary dynamically, can also be done in the editor
	# See: https://docs.godotengine.org/en/stable/tutorials/3d/using_gridmaps.html
	
	var mesh_library = MeshLibrary.new()
	
	for structure in structures:
		var id = mesh_library.get_last_unused_item_id()

		# Create the item and set its mesh
		mesh_library.create_item(id)
		var mesh = get_mesh(structure.model)
		mesh_library.set_item_mesh(id, mesh)

		# Optionally set mesh transform (if needed)
		mesh_library.set_item_mesh_transform(id, Transform3D.IDENTITY)

		var collision_shape = BoxShape3D.new()
		add_collision_shape_to_mesh(mesh_library, id, collision_shape)
		
		var x = mesh_library.get_item_shapes(id)
		print('was', x)

		
	gridmap.mesh_library = mesh_library
	
	update_structure()
	update_cash()

func add_collision_shape_to_mesh(mesh_library: MeshLibrary, id: int, collision_shape: Shape3D):
	var shapes_array = []

	# Move the collision shape up by 0.5 units
	var shape_transform = Transform3D(Basis(), Vector3(0, 0.5, 0)) # Move the collision shape's origin up

	# Add the shape and transform to the array
	shapes_array.append([collision_shape, shape_transform])

	# Apply the shapes to the item in the MeshLibrary
	mesh_library.set_item_shapes(id, shapes_array)


func _physics_process(delta):
	if not is_build_mode_active:
		visible = false
		return
	visible = true

	# Perform raycast from camera in _physics_process to ensure accuracy
	var ray_origin = view_camera.project_ray_origin(get_viewport().get_mouse_position())
	var ray_direction = view_camera.project_ray_normal(get_viewport().get_mouse_position())

	var ray_query = PhysicsRayQueryParameters3D.new()
	ray_query.from = ray_origin
	ray_query.to = ray_origin + ray_direction * 1000
	ray_query.collision_mask = 0xFFFFFFFF ^ (1 << 2) # Exclude layer 2
	var result = get_world_3d().direct_space_state.intersect_ray(ray_query)
	if result.size() > 0:
		var world_position = result.position
		var gridmap_position = Vector3(round(world_position.x), round(world_position.y), round(world_position.z))

		# Move the selector and highlight box to the topmost position in the grid
		update_selector_position(gridmap_position, delta)

		if is_building:
			action_build(Vector3i(gridmap_position))
		if is_demolishing:
			action_demolish(Vector3i(gridmap_position))

func update_selector_position(target_position: Vector3, delta: float):
	var adjusted_position = target_position
	
	# Find the topmost block at this position
	var grid_position = Vector3i(adjusted_position)
	var hovered_block = gridmap.get_cell_item(grid_position)
	
	# Move up in Y until an empty cell is found
	while hovered_block != -1:
		adjusted_position.y += 1
		grid_position = Vector3i(adjusted_position)
		hovered_block = gridmap.get_cell_item(grid_position)
	
	# Update the selector position to the topmost available spot
	selector.position = lerp(selector.position, adjusted_position, delta * 40)

	
func _unhandled_input(event):
	# Start building when mouse button is pressed
	if event.is_action_pressed("build"):
		var ray_origin = view_camera.project_ray_origin(get_viewport().get_mouse_position())
		var ray_direction = view_camera.project_ray_normal(get_viewport().get_mouse_position())

		# Create the raycast query parameters
		var ray_query = PhysicsRayQueryParameters3D.new()
		ray_query.from = ray_origin
		ray_query.to = ray_origin + ray_direction * 1000 # Length of the ray
		ray_query.collide_with_areas = true
		ray_query.collide_with_bodies = true
		ray_query.collide_with_areas = true
		ray_query.collide_with_bodies = true
		ray_query.collision_mask = 0xFFFFFFFF ^ (1 << 2) # Exclude layer 2

		var space_state = get_world_3d().direct_space_state
		var result = space_state.intersect_ray(ray_query)

		if result.size() > 0:
			var world_position = result.position
			var gridmap_position = Vector3(round(world_position.x), round(world_position.y), round(world_position.z))
			
			# Adjust position for placing on top of the highest block in the column
			var gridmap_position_i = Vector3i(gridmap_position)
			var hovered_block = gridmap.get_cell_item(gridmap_position_i)

			# Loop to find the topmost block in the current column
			while hovered_block != -1:
				gridmap_position.y += 1
				gridmap_position_i = Vector3i(gridmap_position)
				hovered_block = gridmap.get_cell_item(gridmap_position_i)
			
			# Now place the block at the topmost free position
			action_build(Vector3i(gridmap_position))
	
	# Stop building when the mouse button is released
	if event.is_action_released("build"):
		is_building = false

	# Start demolishing when mouse button is pressed
	if event.is_action_pressed("demolish"):
		var ray_origin = view_camera.project_ray_origin(get_viewport().get_mouse_position())
		var ray_direction = view_camera.project_ray_normal(get_viewport().get_mouse_position())

		# Create the raycast query parameters for demolishing
		var ray_query = PhysicsRayQueryParameters3D.new()
		ray_query.from = ray_origin
		ray_query.to = ray_origin + ray_direction * 1000 # Length of the ray
		ray_query.collide_with_areas = true
		ray_query.collide_with_bodies = true

		var space_state = get_world_3d().direct_space_state
		var result = space_state.intersect_ray(ray_query)

		if result.size() > 0:
			var world_position = result.position
			var gridmap_position = Vector3(round(world_position.x), round(world_position.y), round(world_position.z))

			# Demolish the structure at the detected position
			action_demolish(Vector3i(gridmap_position))
	
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
	# Start by checking the block at the gridmap position
	var build_position = gridmap_position
	
	# Check for the highest block at this position
	while gridmap.get_cell_item(build_position) != -1:
		# If a block exists at this position, move up by one unit in Y
		build_position.y += 1
	
	# Now place the block at the empty spot on top of the detected block
	gridmap.set_cell_item(build_position, index, gridmap.get_orthogonal_index_from_basis(selector.basis))
	
	# Deduct the structure's price and update cash display
	map.cash -= structures[index].price
	update_cash()


# Demolish (remove) a structure
func action_demolish(gridmap_position):
	gridmap.set_cell_item(gridmap_position, -1)

# Rotates the 'cursor' 90 degrees

func action_rotate():
	if Input.is_action_just_pressed("rotate"):
		selector.rotate_y(deg_to_rad(-90))

# Toggle between structures to build

func action_structure_toggle():
	if Input.is_action_just_pressed("structure_next"):
		index = wrap(index + 1, 0, structures.size())
	
	if Input.is_action_just_pressed("structure_previous"):
		index = wrap(index - 1, 0, structures.size())

	update_structure()

func update_structure():
	# Clear previous structure preview in selector
	for n in selector_preview_container.get_children():
		selector_preview_container.remove_child(n)
		n.queue_free()

	# Create new structure preview in selector
	var model = structures[index].model.instantiate()

	# Disable collisions recursively for all CollisionObject3D nodes
	disable_collisions(model)

	# Add the model to the preview container
	selector_preview_container.add_child(model)
	model.position.y += 0.25

# Helper function to disable collisions in the model
func disable_collisions(node: Node):
	if node is CollisionObject3D:
		node.collision_layer = 0 # Disable collision layer
		node.collision_mask = 0 # Disable collision mask

	# Recursively check all children of the node
	for child in node.get_children():
		disable_collisions(child)

	
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
