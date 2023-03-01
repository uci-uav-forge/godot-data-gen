extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var charactersList

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize() # initialize random seed
	charactersList = $Characters.get_children()
	var randomCharacter = charactersList[randi() % len(charactersList)]
	add_child(randomCharacter.duplicate())
	print(randomCharacter)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
