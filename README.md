# Data Generation 

## Instructions
To run this you need to import this repo in the Godot game engine (tested on 4.1)

1. make sure the data location is clear: `./clear_data.sh`
2. modify `Scripts/gen_training_data.gd` for the number of images you want to generate, and whatever other parameters you want to change
3. open `project.godot` with Godot, then run the project (triangle button in top right). The progress will be shown in the debug console. The location of the data after this depends on your system. On linux, the path is written in the `go_to_data.sh` script, otherwise you'd have to look up where the `user://` path goes to on your platform.
4. Once data is generated, modify the top of `godot_to_shape_labels.py` to point to the data folder, then run that script. If you get python errors about imports, just make sure you have all the stuff installed.
5. After that, the data will be in the `data` folder. Move and rename that to wherever you need it to be for training.

## Misc.

Character models are from https://sketchfab.com/apatel/collections/dl-humanoid-characters-2912fdee14b24cafaaa26f3a961b6606
