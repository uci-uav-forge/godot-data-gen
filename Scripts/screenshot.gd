extends Camera

onready var scene_ready = true
onready var index = 0
onready var root = get_tree().get_root().get_node("Root")
onready var just_people_nodes = []
onready var shapes_list = preload("res://Shapes.tscn").instance().get_children()
onready var symbols = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

func _ready():
	randomize()
	var res_directory = Directory.new()
	res_directory.make_dir("images")
	res_directory.make_dir("masks")

	var scene = preload("res://people.tscn")
	var ppl = scene.instance()
	var crowd_node = ppl.get_children()[0].get_children()[0].get_children()[0].get_children()[0].get_children()[0].duplicate()
	var people_regex = RegEx.new()
	people_regex.compile("AttachHelper")
	for node in crowd_node.get_children():
		var result = people_regex.search(node.name) 
		if result:
			just_people_nodes.append(node)

func prepForSegmentation(node, color: Color):
	if node is MeshInstance:
		node.material_override = SpatialMaterial.new()
		node.material_override.flags_unshaded=true
		node.material_override.albedo_color = color
	else:
		for child in node.get_children():
			prepForSegmentation(child, color)

func takeScreenshot(file_name):
	var image = get_viewport().get_texture().get_data()
	image.save_png("res://%s" % file_name)
	
func makeShapeTarget():
	var shape = shapes_list[randi()%len(shapes_list)].duplicate()
	shape.material_override = SpatialMaterial.new()
	#shape.material_override.flags_unshaded=true
	shape.material_override.albedo_color = Color(randf(), randf(), randf())
	var label = Label3D.new()
	label.text = symbols[randi()%len(symbols)]
	label.font = DynamicFont.new()
	label.font.font_data = load("res://fonts/OpenSans/OpenSans-Bold.ttf")#DynamicFontData.new()
	#label.font.font_data.font_path = 
	label.font.size = 100
	label.modulate = Color(randf(), randf(), randf())
	label.rotate_x(-PI/2)
	shape.add_child(label)
	label.translate(Vector3(0,0.01,0))
	return shape
	

func gen_train_image():
	scene_ready = false
	var random_person = just_people_nodes[randi()%len(just_people_nodes)].duplicate()
	root.add_child(random_person)
	var num_shapes = randi()%10
	var shapes = []
	for _s in range(num_shapes):
		var shape = makeShapeTarget()
		root.add_child(shape)
		shape.translation = Vector3(randi()%10,randi()%10,randi()%10)
		shapes.append(shape)
	random_person.translation=Vector3(randi()%10,randi()%10,randi()%10)
	random_person.scale=Vector3.ONE*0.05
	yield(VisualServer, "frame_post_draw")
	takeScreenshot("images/image%s.png" % index)
	prepForSegmentation(random_person, Color(1,1,1))
	prepForSegmentation(root.get_node("Floor"), Color(0,0,0))
	for shape in shapes:
		prepForSegmentation(shape, Color(1,0,0))
	yield(VisualServer, "frame_post_draw")
	takeScreenshot("masks/mask%s.png" % index)
	random_person.free()
	for shape in shapes:
		shape.free()
	root.get_node("Floor").material_override = null
	index += 1
	scene_ready = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if scene_ready:
		gen_train_image()
