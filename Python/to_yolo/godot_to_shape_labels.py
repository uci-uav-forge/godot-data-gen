# takes dataset with masks generated with godot and turns it into a dataset with labels for YOLOv8
from data_gen_utils import get_polygon, preprocess_img
import os
import cv2
import json
import numpy as np
from tqdm import tqdm
from pathlib import Path
import yaml

# Determine OS and set data directory
import platform
import sys

if platform.system() == "Windows":
    # For Windows, use APPDATA environment variable
    appdata = os.environ.get("APPDATA")
    data_base = Path(appdata) / "Godot" / "app_userdata" / "forge-godot"
else:
    # For Linux
    user = os.environ["USER"]
    data_base = Path(f"/home/{user}/.local/share/godot/app_userdata/forge-godot")

# Find all godot_data* folders
dataset_dirs = sorted(list(data_base.glob('godot_data*')))

if not dataset_dirs:
    print(f"No godot_data* folders found in {data_base}")
    print("Have you run the Godot project to generate data?")
    sys.exit(1)

for idx, dataset_dir in enumerate(dataset_dirs):
    num_frames = sum(1 for _ in (dataset_dir / 'images').glob("*.png"))
    print(f"{idx}\t{num_frames} frames\t{dataset_dir.name}")

dir_selected = input(
    "Enter index of log directory to process (default -1, last one in list): "
)
if dir_selected == "":
    dir_index = -1
else:
    dir_index = int(dir_selected)
INPUT_DIR = dataset_dirs[dir_index]


def gen_img(num, num_images, input_dir, output_dir, shapes_to_categories):
    if int(num) < 0.85 * num_images:
        split_name = "train"
    elif int(num) < 0.95 * num_images:
        split_name = "validation"
    else:
        split_name = "test"

    img_path = input_dir / "images" / f"image{num}.png"
    img = cv2.imread(str(img_path))
    if img is None:
        tqdm.write(f"image read error for {img_path}")
        return

    img = preprocess_img(img)
    file_contents = ""
    mask_dir = input_dir / "masks" / str(num)
    if not mask_dir.exists():
        tqdm.write(f"mask directory missing: {mask_dir}")
        return

    for mask_file_name in os.listdir(mask_dir):
        mask_path = mask_dir / mask_file_name
        shape_name = mask_file_name.split("_")[0].split(",")[0]
        shape_name = "".join(filter(lambda c: c.isalpha(), shape_name))

        if shape_name not in shapes_to_categories:
            tqdm.write(f"unknown shape '{shape_name}' in {mask_path}")
            continue

        mask = cv2.imread(str(mask_path), cv2.IMREAD_GRAYSCALE)
        if mask is None:
            tqdm.write(f"mask read error for {mask_path}")
            continue

        white_pixels = np.where(mask > 127)
        if len(white_pixels[0]) == 0:
            if os.getenv("VERBOSE") is not None:
                tqdm.write(f"no mask found for {mask_path}")
            continue

        y_min, y_max = white_pixels[0].min(), white_pixels[0].max()
        x_min, x_max = white_pixels[1].min(), white_pixels[1].max()

        x_center = ((x_min + x_max) / 2) / mask.shape[1]
        y_center = ((y_min + y_max) / 2) / mask.shape[0]
        width = (x_max - x_min) / mask.shape[1]
        height = (y_max - y_min) / mask.shape[0]

        file_contents += (
            f"{shapes_to_categories[shape_name]} {x_center:.6f} {y_center:.6f} "
            f"{width:.6f} {height:.6f}\n"
        )

    label_file = output_dir / "labels" / split_name / f"image{num}.txt"
    with open(label_file, "w") as f:
        f.write(file_contents)

    cv2.imwrite(str(output_dir / "images" / split_name / f"image{num}.png"), img)


def main():
    datagen_dir = os.path.dirname(os.path.abspath(__file__))
    categories_to_shapes = json.load(open(f"{datagen_dir}/shape_name_labels.json","r"))
    shapes_to_categories = {shape:category for category, shape in categories_to_shapes.items()}
    output_dir = Path(f"{INPUT_DIR}/yolo")
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
    
    yolo_cmd = f'yolo detect train data={output_dir}/dataset_config.yaml model=yolo11n.pt epochs=100 imgsz=1280'
    print(yolo_cmd)
if __name__ == "__main__":
    main()

    