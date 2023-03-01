extends Camera
# attach this to a Camera node and 
# it'll take a screenshot once the 
# scene starts running
var first = true

func _ready():
	pass
	#get_viewport().set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)	

func prepForSegmentation(node, color: Color):
	if node is MeshInstance:
		# make material 
		for surface_idx in range(node.mesh.get_surface_count()):
			node.mesh = node.mesh.duplicate()
			node.mesh.surface_set_material(surface_idx, SpatialMaterial.new())
			node.mesh.surface_get_material(surface_idx).flags_unshaded = true
			node.mesh.surface_get_material(surface_idx).albedo_color = color
	else:
		if node == null:
			return
		for child in node.get_children():
			prepForSegmentation(child, color)

func takeScreenshot(file_name):
	var image = get_viewport().get_texture().get_data()
	image.save_png("res://%s" % file_name)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if first:
		var scene = preload("res://Naruto.tscn")
		var new_naruto = scene.instance()
		new_naruto.scale = Vector3(0.05,0.05,0.05)
		get_tree().get_root().get_node("Root").add_child(new_naruto)
		takeScreenshot("image.png")
		yield(VisualServer, "frame_post_draw")
		prepForSegmentation(new_naruto, Color(1,0,0))
		
		#prepForSegmentation(get_node("Floor"), Color(0,0,0))
		takeScreenshot("mask.png")
		yield(VisualServer, "frame_post_draw")
		first=false
