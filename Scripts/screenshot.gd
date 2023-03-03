extends Camera

# get characters from here: https://sketchfab.com/apatel/collections/dl-humanoid-characters-2912fdee14b24cafaaa26f3a961b6606

# attach this to a Camera node and 
# it'll take a screenshot once the 
# scene starts running
var first = true
var frame
var root
func _ready():
	randomize()
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
		first=false
		var scene = preload("res://people.tscn")
		var ppl = scene.instance()
		var crowd_node = ppl.get_children()[0].get_children()[0].get_children()[0].get_children()[0].get_children()[0].duplicate()
		crowd_node.scale=Vector3(0.1,0.1,0.1)		
		var people_regex = RegEx.new()
		people_regex.compile("AttachHelper")
		var just_people_nodes = []
		for node in crowd_node.get_children():
			var result = people_regex.search(node.name) 
			if result:
				print("yay!")
				just_people_nodes.append(node)
		#print(just_people_nodes)
		var random_person = just_people_nodes[randi()%len(just_people_nodes)].duplicate()
		#root.add_child(crowd_node)
		root.add_child(random_person)
		random_person.translation=Vector3(randi()%10,randi()%10,randi()%10)
		random_person.scale=Vector3.ONE*0.05
		yield(VisualServer, "frame_post_draw")
		takeScreenshot("image.png")
		prepForSegmentation(random_person, Color(1,1,1))
		prepForSegmentation(root.get_node("Floor"), Color(0,0,0))
		yield(VisualServer, "frame_post_draw")
		takeScreenshot("mask.png")
		#get_tree().reload_current_scene()
