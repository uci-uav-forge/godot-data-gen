extends Camera

# get characters from here: https://sketchfab.com/apatel/collections/dl-humanoid-characters-2912fdee14b24cafaaa26f3a961b6606

# attach this to a Camera node and 
# it'll take a screenshot once the 
# scene starts running
var first = true
var root
func _ready():
	root = get_tree().get_root().get_node("Root")
	#get_viewport().set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)	

func prepForSegmentation(node, color: Color):
	if node is MeshInstance:
		# make material 

		node.material_override = SpatialMaterial.new()
		node.material_override.flags_unshaded=true
		node.material_override.albedo_color = color
	else:
		for child in node.get_children():
			prepForSegmentation(child, color)

func takeScreenshot(file_name):
	var image = get_viewport().get_texture().get_data()
	image.save_png("res://%s" % file_name)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if first:
		var scene = preload("res://people.tscn")
		var ppl = scene.instance()
		root.add_child(ppl)
		takeScreenshot("image.png")
		yield(VisualServer, "frame_post_draw")
		prepForSegmentation(ppl, Color(1,0,0))
		prepForSegmentation(root.get_node("Floor"), Color(0,0,0))
		takeScreenshot("mask.png")
		yield(VisualServer, "frame_post_draw")
		#get_tree().reload_current_scene()
		first=false
