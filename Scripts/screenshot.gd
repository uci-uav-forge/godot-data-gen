extends Camera
# attach this to a Camera node and 
# it'll take a screenshot once the 
# scene starts running
var first = true
var charactersList

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize() # initialize random seed
	var root = get_tree().get_root().get_node("Root")
	print(root.get_children())
	charactersList = root.get_node("Characters").get_children()

func prepForSegmentation(node, color: Color):
	if node is MeshInstance:
		# make material 
		for surface_idx in range(node.mesh.get_surface_count()):
			node.mesh.surface_set_material(surface_idx, SpatialMaterial.new())
			node.mesh.surface_get_material(surface_idx).flags_unshaded = true
			node.mesh.surface_get_material(surface_idx).albedo_color = color
	else:
		for child in node.get_children():
			prepForSegmentation(child, color)

		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if first:
		print("screenshotting!")
		var randomCharacter = charactersList[randi() % len(charactersList)]
		var duplicatedInstance = randomCharacter.duplicate()
		prepForSegmentation(duplicatedInstance, Color(1, 0, 0, 1))
		add_child(duplicatedInstance)
		get_viewport().set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
		yield(VisualServer, "frame_post_draw")
		first = false
		var image = get_viewport().get_texture().get_data()
		image.save_png("res://screenshot.png")
