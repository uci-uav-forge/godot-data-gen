
extends Object

class_name Helpers

static func get_people_nodes():
	var scene = preload("res://people.tscn")
	var ppl = scene.instantiate()
	var crowd_node = ppl.get_children()[0].get_children()[0].get_children()[0].get_children()[0].get_children()[0].duplicate()
	var people_regex = RegEx.new()
	people_regex.compile("AttachHelper")
	var just_people_nodes = []
	for node in crowd_node.get_children():
		var result = people_regex.search(node.name) 
		if result:
			just_people_nodes.append(node)

	return just_people_nodes

static func save_image(image, data_folder_name, file_name):
	var save_location_name = "user://%s/%s" % [data_folder_name,file_name]
	image.save_png(save_location_name)

static func takeScreenshot(node, file_name, data_folder_name):
	var image = node.get_viewport().get_texture().get_image()
	save_image(image, data_folder_name, file_name)

static func place_target(target, position):
	target.scale_object_local(randf_range(0.6, 4)*Vector3(randf_range(0.6, 1.2),randf_range(0.6, 1.2),randf_range(0.6, 1.2)))
	target.rotate_y(randf()*TAU)
	target.position = position
	
static func makeShapeTarget():
	var shapes_list = preload("res://Shapes.tscn").instantiate().get_children()
	var symbol_objects = get_symbol_objects("01ABCDEFGHIJ2KLMNOPQRST3UVWXYZ456789")
	var colors_dict = Colors.get_dict()
	var shape = shapes_list[randi()%len(shapes_list)].duplicate()
	shape.material_override = StandardMaterial3D.new()
	shape.material_override.metallic = 0.6 # empirically found to make it blend in with background more with low light
	var all_colors = colors_dict.keys()
	var first_color_index = randi()%len(all_colors)
	var shape_color_name = all_colors[first_color_index]
	var shape_color = colors_dict[shape_color_name][randi()%len(colors_dict[shape_color_name])]
	shape.material_override.albedo_color = Color(shape_color[0]/255.0, shape_color[1]/255.0, shape_color[2]/255.0)
	var symbol_object = symbol_objects[randi()%len(symbol_objects)].duplicate()
	var next_color_index = randi()%(len(all_colors)-1)
	if next_color_index >= first_color_index:
		next_color_index+=1
	var letter_color_name = all_colors[next_color_index] 
	var letter_color = colors_dict[letter_color_name][randi()%len(colors_dict[letter_color_name])]
	symbol_object.modulate = Color(letter_color[0]/255.0, letter_color[1]/255.0, letter_color[2]/255.0)
	symbol_object.rotate_x(-PI/2)
	shape.add_child(symbol_object)
	symbol_object.translate(0.1*Vector3.BACK)
	return [shape, shape.name, symbol_object.text, shape_color_name, letter_color_name]
	
static func gen_person(root):
	var just_people_nodes = get_people_nodes()
	var random_person = just_people_nodes[randi()%len(just_people_nodes)].duplicate()
	root.add_child.call_deferred(random_person)
	random_person.position = 4*Vector3.UP
	random_person.scale= 0.1*Vector3.ONE
	return random_person

static func gen_target(root):
	var shape_and_name = makeShapeTarget()
	var shape = shape_and_name[0]
	var shape_name = shape_and_name[1]
	var alphanumeric = shape_and_name[2]
	var shape_color = shape_and_name[3]
	var letter_color = shape_and_name[4]
	var shape_color_string = shape_color
	var letter_color_string = letter_color
	root.add_child.call_deferred(shape)
	shape.position = 0.1*Vector3.UP
	shape.scale=Vector3.ONE*0.8
	var label_string = "%s,%s,%s,%s" % [shape_name, alphanumeric, shape_color_string, letter_color_string]
	return [shape, label_string]

static func get_symbol_objects(symbols):
	var opensans_bold_font = preload("res://fonts/OpenSans/OpenSans-Bold.ttf")
	var labels_list = []
	for symbol in symbols:
		var label = Label3D.new()
		label.text = symbol
		label.font = opensans_bold_font
		label.font_size=100
		label.outline_size = 0
		labels_list.append(label)

	return labels_list

# https://godotengine.org/qa/5175/how-to-get-all-the-files-inside-a-folder
static func list_files_in_directory(path):
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
