# takes dataset with masks generated with godot and turns it into a dataset with labels for YOLOv8
from data_gen_utils import get_polygon, preprocess_img
import os
import cv2
import json
import numpy as np
from tqdm import tqdm
from pathlib import Path
import yaml

# user = os.environ["USER"]
# # for linux
# dataset_dirs = sorted(list(Path(f"/home/{user}/.local/share/godot/app_userdata/forge-godot").glob('godot_data*')))

# for idx, dataset_dir in enumerate(dataset_dirs):
#     num_frames = sum(1 for _ in (dataset_dir / 'images').glob("*.png"))
#     print(f"{idx}\t{num_frames} frames\t{str(dataset_dir).split('logs/')[-1]}")

# dir_selected = input(
#     "Enter index of log directory to process (default -1, last one in list): "
# )
# if dir_selected == "":
#     dir_index = -1
# else:
#     dir_index = int(dir_selected)
# INPUT_DIR = dataset_dirs[dir_index]

# for windows (change username)
# input_dir = "/mnt/c/Users/sch90/AppData/Roaming/Godot/app_userdata/forge-godot/godot_data"

INPUT_DIR = "C:\\Users\\Bran\\AppData\\Roaming\\Godot\\app_userdata\\forge-godot\\godot_data_1730248253"


def gen_img(num, num_images, input_dir, output_dir, shapes_to_categories):
    if int(num)<0.85*num_images:
        split_name = "train"
    elif int(num)<0.95*num_images:
        split_name = "validation"
    else:
        split_name = "test" 
    img = cv2.imread(f"{input_dir}/images/image{num}.png")
    if img is None:
        tqdm.write(f"image read error for {input_dir}/images/image{num}.png")
        return
    img = preprocess_img(img)
    file_contents = ""
    for mask_file_name in os.listdir(f"{input_dir}/masks/{num}"):
        mask_path = f"{input_dir}/masks/{num}/{mask_file_name}"
        shape_name = mask_file_name.split("_")[0].split(",")[0] 
        mask = cv2.imread(mask_path)
        polygon = get_polygon(mask)

        if len(polygon) <= 2:
            if os.getenv("VERBOSE") is not None:
                tqdm.write(f"no polygon found for {mask_path}")
            return 
        normalized_polygon = polygon / np.array([mask.shape[1], mask.shape[0]])
        file_contents+=f"{shapes_to_categories[shape_name]} {' '.join(map(str, normalized_polygon.flatten()))}\n"
    with open(f"{output_dir}/labels/{split_name}/image{num}.txt", "w") as f:
        f.write(file_contents)
    cv2.imwrite(f"{output_dir}/images/{split_name}/image{num}.png", img)

def main():
    datagen_dir = os.path.dirname(os.path.abspath(__file__))
    categories_to_shapes = json.load(open(f"{datagen_dir}/shape_name_labels.json","r"))
    shapes_to_categories = {shape:category for category, shape in categories_to_shapes.items()}
    output_dir = f"{INPUT_DIR}/yolo"
    os.makedirs(output_dir, exist_ok=True)
    for split_name in ["train", "validation", "test"]:
        os.makedirs(f"{output_dir}/labels/{split_name}", exist_ok=True)
        os.makedirs(f"{output_dir}/images/{split_name}", exist_ok=True)
    num_images = len(os.listdir(f"{INPUT_DIR}/images"))

    yaml.dump(
        {
            "path": output_dir,
            "train": "images/train",
            "val": "images/validation",
            "test": "images/test",
            "names": {
                int(v): k for k, v in shapes_to_categories.items()
            }
        },
        open(f"{output_dir}/dataset_config.yaml", "w"),
        
        sort_keys=False
    )

    for i in tqdm(range(num_images)):
        gen_img(i, num_images, INPUT_DIR, output_dir, shapes_to_categories)
    
    yolo_cmd = f'yolo detect train data={output_dir}/dataset_config.yaml model=yolo11n.pt epochs=100 imgsz=640'
    print(yolo_cmd)
if __name__ == "__main__":
    main()

    