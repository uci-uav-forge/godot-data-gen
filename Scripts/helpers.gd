extends Object
class_name Helpers

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

static func gen_targets(root):
	var targets = preload("res://Targets.tscn").instantiate().get_children()
	var i = randi_range(0,len(targets)-1)
	var target = targets[i].duplicate() # randomly chosen
	var name = targets[i].name
	target.scale = target.scale*0.025 # hand chosen value, adjust as needed
	root.add_child(target)
	return [target, name]

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
