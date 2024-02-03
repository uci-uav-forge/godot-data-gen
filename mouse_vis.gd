extends Camera3D
@onready var root = get_tree().get_root().get_node("Root")
@onready var cube = root.get_node("cube")
@onready var ray = root.get_node("ray")


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var mouse_pos = get_viewport().get_mouse_position()
	var x = mouse_pos[0]
	var y = mouse_pos[1]
	var w = 1920
	var h = 1080
	
	var vfov = 30
	var focal_len = h/(2*tan(deg_to_rad(vfov/2)))
	
	var x_rot = self.rotation_degrees.x
	var y_rot = self.rotation_degrees.y
	var z_rot = self.rotation_degrees.z
	var camera_position = self.position
	
	var cam_look = Vector3(x-w/2, h/2-y, -focal_len)
	var rotated_vector = cam_look
	rotated_vector = rotated_vector.rotated(Vector3(1,0,0) ,deg_to_rad(x_rot))
	rotated_vector = rotated_vector.rotated(Vector3(0,1,0) ,deg_to_rad(y_rot))
	rotated_vector = rotated_vector.rotated(Vector3(0,0,1) ,deg_to_rad(z_rot))
	
	
	var t = -camera_position[1]/rotated_vector[1]
	var target_position = camera_position + t*rotated_vector
	cube.position = target_position
