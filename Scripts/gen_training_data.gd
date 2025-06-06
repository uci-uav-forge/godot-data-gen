extends Camera3D

var num_imgs = 10_000
var max_rotation = 10
var brightness_min = 0.1
var brightness_max = 1.5
var output_folder_name = "godot_data_%d" % (int(Time.get_unix_time_from_system()))
var position_noise = 1 # range of uniform noise added to the position of the objects. By default, they are placed randomly on a 3-unit spaced grid centered at the image center.
var max_targets_per_image = 2 # maximum number of targets in an image. The actual number will be uniformly random between 1 and this number

@onready var scene_ready = true
@onready var index = 0
@onready var root = get_tree().get_root().get_node("Root")
@onready var global_light: Light3D = root.get_node("Light")
@onready var world_floor = root.get_node("Floor")
@onready var backgrounds_list = [] # filled with materials in _ready
var res_directory


func _ready():
	set_physics_process(false)
	randomize()
	
	res_directory = DirAccess.open("user://")
	res_directory.remove("user://%s" % output_folder_name)
	res_directory.make_dir(output_folder_name)
	res_directory = DirAccess.open("user://%s" % output_folder_name)
	res_directory.make_dir("images")
	res_directory.make_dir("masks")
	
	print("Results Directory: %s" % res_directory.get_current_dir())
	
	# Initialize shared FastNoiseLite in set_meta
	var fast_noise = FastNoiseLite.new()
	fast_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	fast_noise.frequency = 0.03  # Controls how bumpy the noise pattern is
	var noise_image = fast_noise.get_image(512, 512, false, false)
	var noise_tex = ImageTexture.create_from_image(noise_image)
	self.set_meta("shared_noise_tex", noise_tex)
	
	var backgrounds_directory_list = Helpers.list_files_in_directory("res://backgrounds")
	var perlin_shader := preload("res://Scripts/perlin_shader.gdshader")
	for background_path in backgrounds_directory_list:
		var full_path = "res://backgrounds/%s" % background_path # no file error checking

		var tex_img = Image.new()
		var err = tex_img.load(full_path)
		if err != OK:
			print("Failed to load:", full_path)
			continue

		var tex = ImageTexture.create_from_image(tex_img)
		var mat := ShaderMaterial.new()
		mat.shader = perlin_shader
		mat.set_shader_parameter("base_tex", tex)
		mat.set_shader_parameter("noise_strength", 0.3)  
		mat.set_shader_parameter("noise_scale", 8.0)      
		backgrounds_list.append(mat) 
	

func generatePositions(spacing: int = 5):
	var positions = []
	# ensures that the grid spans *most* of the FOV, erring on the side of caution because we don't want to place objects outside the image.
	var positions_grid_range = self.position.y * (tan(deg_to_rad(max_rotation)) - tan(deg_to_rad(max_rotation - self.fov/2))) * 0.7
	for x in range(-positions_grid_range, positions_grid_range, spacing):
		for z in range(-positions_grid_range, positions_grid_range, spacing):
			positions.append(Vector3(x,0.2,z))
	positions.shuffle()
	return positions

func prepForSegmentation(node, color: Color):
	if node is MeshInstance3D:
		node.material_override = StandardMaterial3D.new()
		node.material_override.flags_unshaded=true
		node.material_override.albedo_color = color
	elif node is Label3D:
		node.hide()
	for child in node.get_children():
		prepForSegmentation(child, color)


func get_target_objects_and_labels():
	var num_shapes = randi()%(max_targets_per_image+1)
	if (num_shapes == 0):
		num_shapes = 1
		
	var target_objects = []
	var target_labels = []
	for _i in range(num_shapes):
		var target = Helpers.gen_targets(root)
		target_objects.append(target[0])
		target_labels.append(target[1])
	
	return [target_objects, target_labels]

func gen_train_image():
	res_directory.make_dir("masks/%s" % index)
	var target_objects_and_labels = get_target_objects_and_labels()
	var target_objects = target_objects_and_labels[0]
	var target_labels = target_objects_and_labels[1]
	print(target_labels)
	
	self.fov = randi_range(70, 80)
	#self.rotation_degrees = Vector3(-90+randi_range(-max_rotation, max_rotation), randi_range(0,360), 0)
	var dist_from_center = self.position.y * tan(-PI/2-self.rotation.x)
	var picture_center = Vector3(0,0,dist_from_center).rotated(Vector3.UP, self.rotation.y)
	
	var positions = generatePositions()
	
	var pos_idx = 0
	for obj in target_objects:
		obj.rotate_y(randf()*TAU)
		obj.position = picture_center
		obj.position += positions[pos_idx]+ Vector3(randf_range(-position_noise, position_noise), 0, randf_range(-position_noise, position_noise))
		pos_idx+=1
		obj.scale_object_local(randf_range(0.9, 1.1)*Vector3(randf_range(0.6, 1.2),randf_range(0.6, 1.2),randf_range(0.6, 1.2)))

	global_light.light_energy = randf_range(brightness_min, brightness_max)
	global_light.rotation_degrees = Vector3(randi_range(-30, -150), randi_range(0,360), 0)
	
	var mat = backgrounds_list[randi()%len(backgrounds_list)].duplicate()
	mat.set_shader_parameter("noise_strength", randf_range(0.3, 0.5))
	mat.set_shader_parameter("noise_scale", randf_range(3.0, 6.0))
	mat.set_shader_parameter("noise_tex", self.get_meta("shared_noise_tex")) 
	#mat.set_shader_parameter("time_seed", randf() * 1000.0)              # Random static offset
	world_floor.material_override = mat

	#world_floor.material_override = backgrounds_list[randi()%len(backgrounds_list)]
	#world_floor.scale = Vector3(randi_range(50, 100), 0.001, randi_range(50, 100))
	
	await get_tree().process_frame
	Helpers.takeScreenshot(self, "images/image%s.png" % index, output_folder_name)
	prepForSegmentation(world_floor, Color.BLACK)
	for obj in target_objects:
		obj.hide()
	
	for i in target_objects.size():
		target_objects[i].show()
		prepForSegmentation(target_objects[i], Color.WHITE)
		await get_tree().process_frame
		Helpers.takeScreenshot(self, "masks/%s/%s_%s.png" % [index, target_labels[i] , i], output_folder_name)
		target_objects[i].free()
	
	world_floor.material_override = null
	index += 1
	scene_ready = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if scene_ready:
		scene_ready = false
		if index%10==0:
			print("%s/%s" % [index, num_imgs])
		if index >= num_imgs:
			get_tree().quit()
		gen_train_image()
