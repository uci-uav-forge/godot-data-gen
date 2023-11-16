# Data Generation 

## Instructions
To run this you need to import this repo in the Godot game engine (tested on 4.1)

1. make sure the data location is clear: `./clear_data.sh`
2. modify `Scripts/gen_training_data.gd` for the number of images you want to generate, and whatever other parameters you want to change
3. open `project.godot` with Godot, then run the project (triangle button in top right). The progress will be shown in the debug console.
4. Once data is generated, run `python3 godot_to_shape_labels.py`. If you get errors about imports, just make sure you have all the stuff installed.
5. After that, the data will be in the `data` folder. Move and rename that to wherever you need it to be for training.

## Misc.

Character models are from https://sketchfab.com/apatel/collections/dl-humanoid-characters-2912fdee14b24cafaaa26f3a961b6606
