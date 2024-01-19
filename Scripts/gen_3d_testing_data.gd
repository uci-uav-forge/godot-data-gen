extends Camera3D

@onready var scene_ready = true
@onready var index = 0
@onready var num_imgs = 10
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
@onready var camera_positions = []

func prepare_people_nodes():
	var scene = preload("res://people.tscn")
	var ppl = scene.instantiate()
	var crowd_node = ppl.get_children()[0].get_children()[0].get_children()[0].get_children()[0].get_children()[0].duplicate()
	var people_regex = RegEx.new()
	people_regex.compile("AttachHelper")
	for node in crowd_node.get_children():
		var result = people_regex.search(node.name) 
		if result:
			just_people_nodes.append(node)

func _ready():
	set_physics_process(false)
	randomize()
	
	var position_std = 5
	
	# the targets are all within x [-140, 140] and z [-65, 65]
	var camera_view_area_size = 30
	for cam_x in range(-140+camera_view_area_size/2,140-camera_view_area_size/2,camera_view_area_size):
		for cam_z in range(-65+camera_view_area_size/2, 65-camera_view_area_size/2, camera_view_area_size):
			var rand_pos_drift = Vector3(randfn(0,position_std),randfn(0,position_std),randfn(0,position_std))
			camera_positions.append(Vector3(cam_x,75,cam_z) + rand_pos_drift)
	

	
	res_directory = DirAccess.open("user://")
	res_directory.make_dir(data_folder_name)
	res_directory = DirAccess.open("user://%s" % data_folder_name)
	res_directory.make_dir("images")
	
	prepare_people_nodes()
	
	positions = []
	for x in range(-140, 140, 5):
		for z in range(-65, 65, 5):
			positions.append(Vector3(x,0,z))
	for symbol in symbols:
		var label = Label3D.new()
		label.text = symbol
		label.font = opensans_bold_font
		label.font_size=100
		labels_list.append(label)
	
	positions.shuffle()
	
	var target_positions_save_file = FileAccess.open("user://godot_data/labels.txt", FileAccess.WRITE)
	
	var has_emergent = false # TODO: uncomment this when ready to put people in datset #randi()%2==0
	var num_targets = 5
	if has_emergent:
		num_targets-=1
		var person = gen_person()
		place_target(person, positions.pop_front())
		var pos_string = "%d,%d,%d" % [person.position[0], person.position[1], person.position[2]]
		target_positions_save_file.store_line("person %s" % pos_string)
	
	for _i in range(num_targets):
		var target_and_label = gen_target()
		place_target(target_and_label[0], positions.pop_front())
		var pos_string = "%d,%d,%d" % [target_and_label[0].position[0], target_and_label[0].position[1], target_and_label[0].position[2]]
		target_positions_save_file.store_line("%s %s" % [target_and_label[1], pos_string])
		
	var num_extraneous_targets = randi()%100
	for _i in range(num_extraneous_targets):
		var target = gen_target()[0]
		place_target(target, positions.pop_front())

	global_light.light_energy = randf()*1.5
	global_light.rotation_degrees = Vector3(randi_range(-30, -150), randi_range(0,360), 0)
	
	print("finished ready!")
	
func save_image(image, file_name):
	var save_location_name = "user://%s/%s" % [data_folder_name,file_name]
	print(save_location_name)
	image.save_png(save_location_name)

func takeScreenshot(file_name):
	var image = get_viewport().get_texture().get_image()
	save_image(image, file_name)

func place_target(target, position):
	target.rotate_y(randf()*TAU)
	target.position = position + Vector3(randf()-0.5, 0, randf()-0.5)
	target.scale_object_local(randf_range(0.9, 1.1)*Vector3(randf_range(0.6, 1.2),randf_range(0.6, 1.2),randf_range(0.6, 1.2)))
	
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
	
func gen_person():
	var random_person = just_people_nodes[randi()%len(just_people_nodes)].duplicate()
	root.add_child.call_deferred(random_person)
	random_person.position = 4*Vector3.UP
	random_person.scale= 0.1*Vector3.ONE
	return random_person

func gen_target():
	var shape_and_name = makeShapeTarget()
	var shape = shape_and_name[0]
	var shape_name = shape_and_name[1]
	var alphanumeric = shape_and_name[2]
	var shape_color = shape_and_name[3]
	var letter_color = shape_and_name[4]
	var shape_color_string = "%s-%s-%s" % shape_color
	var letter_color_string = "%s-%s-%s" % letter_color
	var n = root.get_child_count()
	root.add_child.call_deferred(shape)
	shape.position = 0.1*Vector3.UP
	shape.scale=Vector3.ONE*0.8
	var label_string = "%s,%s,%s,%s" % [shape_name, alphanumeric, shape_color_string, letter_color_string]
	return [shape, label_string]
	
func get_target_objects_and_labels():
	var target_objects = []
	var target_labels = []
	if randi()%3==0:
		target_objects.append(gen_person())
		target_labels.append("person")
	var num_shapes = randi()%4
	for _s in range(num_shapes):
		var shape_and_label = gen_target()
		target_objects.append(shape_and_label[0])
		target_labels.append(shape_and_label[1])
	return [target_objects, target_labels]

func gen_train_image():
	var rotation_range = 10
	self.rotation_degrees = Vector3(randi_range(-90-rotation_range, -90+rotation_range), -90, 0)

	if index >= len(camera_positions):
		get_tree().quit()
		return
	self.position = camera_positions[index]

	var position_string  = "%d,%d,%d" % [self.position.x, self.position.y, self.position.z]
	var rotation_string  = "%d,%d,%d" % [self.rotation_degrees.x, self.rotation_degrees.y, self.rotation_degrees.z]
	
	await get_tree().process_frame
	takeScreenshot("images/image%s_%s_%s.png" % [index, position_string, rotation_string])
	scene_ready = true
	index+=1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if scene_ready:
		scene_ready = false
		gen_train_image()
