extends Camera3D

@onready var scene_ready = true
@onready var index = 0
@onready var num_imgs = 100
@onready var root = get_tree().get_root().get_node("Root")
@onready var just_people_nodes = []
@onready var shapes_list = preload("res://Shapes.tscn").instantiate().get_children()
@onready var symbols = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
var res_directory
@onready var global_light: Light3D = root.get_node("Light")
@onready var world_floor = root.get_node("Floor")
@onready var opensans_bold_font = preload("res://fonts/OpenSans/OpenSans-Bold.ttf")
@onready var data_folder_name = "godot_data"
var backgrounds_list
var positions
@onready var threads_queue = []
@onready var labels_list = []

# https://godotengine.org/qa/5175/how-to-get-all-the-files-inside-a-folder
func list_files_in_directory(path):
	var files = []
	var dir = DirAccess.open(path)
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
	set_physics_process(false)
	randomize()
	
	res_directory = DirAccess.open("user://")
	res_directory.remove("user://%s" % data_folder_name)
	res_directory.make_dir(data_folder_name)
	res_directory = DirAccess.open("user://%s" % data_folder_name)
	res_directory.make_dir("images")
	res_directory.make_dir("masks")
	
	var backgrounds_directory_list = list_files_in_directory("res://backgrounds")
	backgrounds_list = []
	for background_path in backgrounds_directory_list:
		var background = load("res://backgrounds/%s" % background_path)
		var bg_mat = StandardMaterial3D.new()
		bg_mat.albedo_texture = background
		backgrounds_list.append(bg_mat)

	var scene = preload("res://people.tscn")
	var ppl = scene.instantiate()
	var crowd_node = ppl.get_children()[0].get_children()[0].get_children()[0].get_children()[0].get_children()[0].duplicate()
	var people_regex = RegEx.new()
	people_regex.compile("AttachHelper")
	for node in crowd_node.get_children():
		var result = people_regex.search(node.name) 
		if result:
			just_people_nodes.append(node)
	
	
	positions = []
	for x in range(-5, 6, 2):
		for z in range(-5, 6, 2):
			positions.append(Vector3(x,0,z))
	for symbol in symbols:
		var label = Label3D.new()
		label.text = symbol
		label.font = opensans_bold_font
		label.font_size=100
		labels_list.append(label)

func prepForSegmentation(node, color: Color):
	if node is MeshInstance3D:
		node.material_override = StandardMaterial3D.new()
		node.material_override.flags_unshaded=true
		node.material_override.albedo_color = color
	elif node is Label3D:
		node.modulate = color
		node.shaded=false
	for child in node.get_children():
		prepForSegmentation(child, color)

func save_image(image, file_name):
	var save_location_name = "user://%s/%s" % [data_folder_name,file_name]
	image.save_png(save_location_name)

func takeScreenshot(file_name):
	var thread = Thread.new()
	var image = get_viewport().get_texture().get_image()
	thread.start(save_image.bind(image, file_name))
	threads_queue.append(thread)
	
func makeShapeTarget():
	var shape = shapes_list[randi()%len(shapes_list)].duplicate()
	shape.material_override = StandardMaterial3D.new()
	var shape_color = [randi_range(0,255), randi_range(0,255), randi_range(0,255)]
	shape.material_override.albedo_color = Color(shape_color[0]/255.0, shape_color[1]/255.0, shape_color[2]/255.0)
	var label = labels_list[randi()%len(labels_list)].duplicate()
	var letter_color = [randi_range(0,255), randi_range(0,255), randi_range(0,255)]
	label.modulate = Color(letter_color[0]/255.0, letter_color[1]/255.0, letter_color[2]/255.0)
	label.rotate_x(-PI/2)
	shape.add_child(label)
	label.translate(0.1*Vector3.BACK)
	return [shape, shape.name, label.text, shape_color, letter_color]

func get_target_objects_and_labels():
	var target_objects = []
	var target_labels = []
	if randi()%3==0:
		var random_person = just_people_nodes[randi()%len(just_people_nodes)].duplicate()
		root.add_child(random_person)
		random_person.position = 4*Vector3.UP
		random_person.scale= 0.1*Vector3.ONE
		target_objects.append(random_person)
		target_labels.append("person")
	var num_shapes = randi()%4
	for _s in range(num_shapes):
		var shape_and_name = makeShapeTarget()
		var shape = shape_and_name[0]
		var shape_name = shape_and_name[1]
		var alphanumeric = shape_and_name[2]
		var shape_color = shape_and_name[3]
		var letter_color = shape_and_name[4]
		var shape_color_string = "%s_%s_%s" % shape_color
		var letter_color_string = "%s_%s_%s" % letter_color
		root.add_child(shape)
		shape.position = 0.1*Vector3.UP
		shape.scale=Vector3.ONE*0.8
		target_objects.append(shape)
		var label_string = "%s,%s,%s,%s" % [shape_name, alphanumeric, shape_color_string, letter_color_string]
		target_labels.append(label_string)
	return [target_objects, target_labels]

func gen_train_image():
	res_directory.make_dir("masks/%s" % index)
	var target_objects_and_labels = get_target_objects_and_labels()
	var target_objects = target_objects_and_labels[0]
	var target_labels = target_objects_and_labels[1]
	var rotation_range = 10
	self.rotation_degrees = Vector3(randi_range(-90-rotation_range, -90+rotation_range), randi_range(0,360), 0)
	var dist_from_center = self.position.y * tan(-PI/2-self.rotation.x)
	var picture_center = Vector3(0,0,dist_from_center).rotated(Vector3.UP, self.rotation.y)
	
	positions.shuffle()
	
	var pos_idx = 0
	for obj in target_objects:
		obj.rotate_y(randf()*TAU)
		obj.position+=picture_center + positions[pos_idx]+ Vector3(randf()-0.5, 0, randf()-0.5)
		pos_idx+=1
		obj.scale_object_local(randf_range(0.9, 1.1)*Vector3(randf_range(0.6, 1.2),randf_range(0.6, 1.2),randf_range(0.6, 1.2)))

	global_light.light_energy = randf()*1.5
	global_light.rotation_degrees = Vector3(randi_range(-30, -150), randi_range(0,360), 0)
	
	world_floor.material_override = backgrounds_list[randi()%len(backgrounds_list)]
	world_floor.scale = Vector3(randi_range(50, 100), 0.001, randi_range(50, 100))
	
	await get_tree().process_frame
	# yield(VisualServer, "frame_post_draw")
	takeScreenshot("images/image%s.png" % index)
	# await get_tree().create_timer(1).timeout
	prepForSegmentation(world_floor, Color.BLACK)
	for obj in target_objects:
		obj.hide()
	
	for i in target_objects.size():
		target_objects[i].show()
		prepForSegmentation(target_objects[i], Color.WHITE)
		await get_tree().process_frame
		#yield(VisualServer, "frame_post_draw")
		takeScreenshot("masks/%s/%s_%s.png" % [index, target_labels[i] , i])
		# await get_tree().create_timer(1).timeout
		target_objects[i].free()
	
	world_floor.material_override = null
	index += 1
	scene_ready = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	while 1:
		if len(threads_queue)==0 or threads_queue[0].is_alive() and len(threads_queue)<10:
			break
		threads_queue[0].wait_to_finish()
		threads_queue.pop_front()
	if scene_ready:
		scene_ready = false
		if index%10==0:
			print("%s/%s" % [index, num_imgs])
		if index >= num_imgs:
			get_tree().quit()
		gen_train_image()
