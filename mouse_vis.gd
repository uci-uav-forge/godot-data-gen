extends Camera3D
@onready var root = get_tree().get_root().get_node("Root")
@onready var cube = root.get_node("cube")
@onready var ray = root.get_node("ray")


# Called when the node enters the scene tree for the first time.
func _ready():
	var rotation_std = 10 
	var rotation_perturbation = Vector3(randfn(0,rotation_std),randfn(0,rotation_std),randfn(0,rotation_std))
	self.rotation_degrees = Vector3(-90, -90, 0) + rotation_perturbation

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var mouse_pos = get_viewport().get_mouse_position()
	var x = mouse_pos[0]
	var y = mouse_pos[1]
	var w = 1920
	var h = 1080
	
	var vfov = 30
	var focal_len = h/(2*tan(deg_to_rad(vfov/2)))
	
	var rot_quat = self.quaternion
	var camera_position = self.position
	
	var cam_look = Vector3(x-w/2, h/2-y, -focal_len)
	var rotated_vector = rot_quat * cam_look
	
	var t = -camera_position[1]/rotated_vector[1]
	var target_position = camera_position + t*rotated_vector
	cube.position = target_position
	
	print(camera_position)
	print(rot_quat)
	print(mouse_pos)
	print(target_position)
	print()
	
	
