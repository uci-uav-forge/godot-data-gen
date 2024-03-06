extends Camera3D

@onready var scene_ready = true
@onready var index = 0
@onready var root = get_tree().get_root().get_node("Root")
var res_directory
@onready var global_light: Light3D = root.get_node("Light")
@onready var world_floor = root.get_node("Floor")
@onready var data_folder_name = "sim_dataset"
var backgrounds_list
var positions
@onready var threads_queue = []
@onready var labels_list = []
@onready var camera_positions = []

func _ready():
	set_physics_process(false)
	randomize()
	
	var position_std = 1
	
	# the targets are all within x [-140, 140] and z [-65, 65]
	var camera_fov = 30
	self.fov = camera_fov
	var camera_view_x = 2*75*tan(deg_to_rad(self.fov/2))
	var camera_view_y = camera_view_x*9/16
	for cam_x in range(-140,140,camera_view_y-5):
		for cam_z in range(-65, 65, camera_view_x-5):
			var rand_pos_drift = Vector3(randfn(0,position_std),randfn(0,position_std),randfn(0,position_std))
			camera_positions.append(Vector3(cam_x,75,cam_z) + rand_pos_drift)
	
	res_directory = DirAccess.open("user://")
	res_directory.make_dir(data_folder_name)
	res_directory = DirAccess.open("user://%s" % data_folder_name)
	res_directory.make_dir("images")
	
	positions = []
	for x in range(-140, 140, 5):
		for z in range(-65, 65, 5):
			positions.append(Vector3(x,0,z))
	
	positions.shuffle()
	
	var target_positions_save_file = FileAccess.open("user://%s/labels.txt" % data_folder_name, FileAccess.WRITE)
	
	var has_emergent = randi()%2==0 # TODO: uncomment this when ready to put people in datset #randi()%2==0
	var num_targets = 5
	if has_emergent:
		num_targets -= 1
		var person = Helpers.gen_person(root)
		Helpers.place_target(person, positions.pop_front())
		var pos_string = "%d,%d,%d" % [person.position[0], person.position[1], person.position[2]]
		target_positions_save_file.store_line("person %s" % pos_string)
	
	for _i in range(num_targets):
		var target_and_label = Helpers.gen_target(root)
		Helpers.place_target(target_and_label[0], positions.pop_front())
		var pos_string = "%d,%d,%d" % [target_and_label[0].position[0], target_and_label[0].position[1], target_and_label[0].position[2]]
		target_positions_save_file.store_line("%s %s" % [target_and_label[1], pos_string])

	global_light.light_energy = 0.2+randf()
	# global_light.rotation_degrees = Vector3(randi_range(-30, -150), randi_range(0,360), 0)
	
	print("finished ready!")
	
func get_target_objects_and_labels():
	var target_objects = []
	var target_labels = []
	if randi()%3==0:
		target_objects.append(Helpers.gen_person(root))
		target_labels.append("person")
	var num_shapes = randi()%4
	for _s in range(num_shapes):
		var shape_and_label = Helpers.gen_target(root)
		target_objects.append(shape_and_label[0])
		target_labels.append(shape_and_label[1])
	return [target_objects, target_labels]

func gen_train_image():
	var rotation_range = 10
	var rotation_std = 1
	var rotation_perturbation = Vector3(randfn(0,rotation_std),randfn(0,rotation_std),randfn(0,rotation_std))
	self.rotation_degrees = Vector3(-90, -90, 0) + rotation_perturbation

	if index >= len(camera_positions):
		get_tree().quit()
		return
	self.position = camera_positions[index]
	
	var position_noise_std = 1
	var written_pos = self.position +  Vector3(randfn(0,position_noise_std),randfn(0,position_noise_std),randfn(0,position_noise_std))

	var position_string  = "%d,%d,%d" % [written_pos.x, written_pos.y, written_pos.z]
	var q = self.quaternion
	var rotation_string  = "%.10f,%.10f,%.10f,%.10f" % [q.x, q.y, q.z, q.w]
	
	await get_tree().process_frame
	Helpers.takeScreenshot(self, "images/image%s_%s.png" % [index, position_string], data_folder_name)
	# output rotation string to images/rotation{index}.txt
	var rotation_file = FileAccess.open("user://%s/images/rotation%s.txt" % [data_folder_name, index], FileAccess.WRITE)
	rotation_file.store_line(rotation_string)
	rotation_file.close()
	index+=1
	scene_ready = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if scene_ready:
		scene_ready = false
		gen_train_image()
