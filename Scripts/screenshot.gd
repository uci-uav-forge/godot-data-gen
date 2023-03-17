extends Camera

onready var scene_ready = true
onready var index = 0
onready var root = get_tree().get_root().get_node("Root")
onready var just_people_nodes = []
onready var shapes_list = preload("res://Shapes.tscn").instance().get_children()
onready var symbols = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
onready var res_directory = Directory.new()
onready var global_light: Light = root.get_node("Light")
onready var world_floor = root.get_node("Floor")
var backgrounds_directory_list

# https://godotengine.org/qa/5175/how-to-get-all-the-files-inside-a-folder
func list_files_in_directory(path):
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with(".") and not file.ends_with(".import"):
			files.append(file)

	dir.list_dir_end()

	return files

func _ready():
	randomize()
	
	res_directory.open("/tmp")
	res_directory.make_dir("images")
	res_directory.make_dir("masks")
	
	backgrounds_directory_list = list_files_in_directory("res://backgrounds")

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
	elif node is Label3D:
		node.modulate = color
		node.shaded=false
	for child in node.get_children():
		prepForSegmentation(child, color)

func takeScreenshot(file_name):
	var image = get_viewport().get_texture().get_data()
	image.save_png("/tmp/%s" % file_name)
	
func makeShapeTarget():
	var shape = shapes_list[randi()%len(shapes_list)].duplicate()
	shape.material_override = SpatialMaterial.new()
	shape.material_override.albedo_color = Color(randf(), randf(), randf())
	var label = Label3D.new()
	label.text = symbols[randi()%len(symbols)]
	label.font = DynamicFont.new()
	label.font.font_data = load("res://fonts/OpenSans/OpenSans-Bold.ttf")
	label.font.size = 100
	label.modulate = Color(randf(), randf(), randf())
	label.rotate_x(-PI/2)
	shape.add_child(label)
	label.translate(Vector3(0,0.01,0))
	return [shape, shape.name]

func get_target_objects_and_labels():
	var target_objects = []
	var target_labels = []
	if (randi()%2)>0:
		var random_person = just_people_nodes[randi()%len(just_people_nodes)].duplicate()
		root.add_child(random_person)
		random_person.translation= Vector3.ZERO
		random_person.scale=Vector3.ONE*0.05
		target_objects.append(random_person)
		target_labels.append("person")
	var num_shapes = randi()%10
	for _s in range(num_shapes):
		var shape_and_name = makeShapeTarget()
		var shape = shape_and_name[0]
		var shape_name = shape_and_name[1]
		root.add_child(shape)
		shape.translation = 0.01*Vector3.UP
		target_objects.append(shape)
		target_labels.append(shape_name)
	return [target_objects, target_labels]

func gen_train_image():
	scene_ready = false	
	res_directory.make_dir("masks/%s" % index)
	var target_objects_and_labels = get_target_objects_and_labels()
	var target_objects = target_objects_and_labels[0]
	var target_labels = target_objects_and_labels[1]
	
	for obj in target_objects:
		obj.rotate_y(randf()*TAU)
		obj.translate(50 * Vector3(randf()-0.5,0,randf()-0.5))
		obj.scale_object_local(rand_range(0.3, 1.7)*Vector3(rand_range(0.8, 1.2),rand_range(0.8, 1.2),rand_range(0.8, 1.2)))

	global_light.light_energy = randf()*1.2
	self.rotation_degrees = Vector3(rand_range(-80, -100), rand_range(0,360), rand_range(0, 360))
	var background_path = backgrounds_directory_list[randi()%len(backgrounds_directory_list)]
	var background = load("res://backgrounds/%s" % background_path)
	world_floor.material_override = SpatialMaterial.new()
	world_floor.material_override.albedo_texture = background
	world_floor.scale = Vector3(rand_range(50, 100), 0.001, rand_range(50, 100))
	
	yield(VisualServer, "frame_post_draw")
	takeScreenshot("images/image%s.png" % index)

	prepForSegmentation(world_floor, Color.black)
	for obj in target_objects:
		obj.hide()
	
	for i in target_objects.size():
		target_objects[i].show()
		prepForSegmentation(target_objects[i], Color.white)
		yield(VisualServer, "frame_post_draw")
		takeScreenshot("masks/%s/%s_%s.png" % [index, target_labels[i], i])
		target_objects[i].free()
	
	world_floor.material_override = null
	index += 1
	scene_ready = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if scene_ready:
		gen_train_image()
