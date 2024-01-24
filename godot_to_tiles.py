# takes dataset with masks generated with godot and turns it into a tile dataset with labels to test the pipeline
# the resulting image directory will contain .import files
# to remove them: find . -type f -name "*.import" -exec rm {} +

from data_gen_utils import get_polygon, give_normalized_bounding_box
import os
import cv2
import json
import numpy as np
from tqdm import tqdm

def preprocess_img(img):
    # blur image with random kernel size
    kernel_size = 3 + 2*np.random.randint(0, 2)
    if np.random.randint(0,2)==0:
        img = cv2.GaussianBlur(img, (kernel_size, kernel_size), 0)
    else:
        img = cv2.boxFilter(img, -1, (kernel_size, kernel_size))
    # add random noise with random variance
    variance = np.random.randint(0, 10)
    img = img + np.random.normal(0, variance, img.shape)
    # clamp values to 0-255
    np.clip(img, 0, 255, out=img)
    return img

def gen_img(num, num_images, input_dir, output_dir, shapes_to_categories, letters_to_categories):
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

    #file content for the tiles will be the indices of "{shape} {letter} {shape_col} {letter_col} {bounding box}"
    # bounding box is defined as {x max} {y max} {x min} {y min} from the polygon array

    for mask_file_name in os.listdir(f"{input_dir}/masks/{num}"):
        mask_path = f"{input_dir}/masks/{num}/{mask_file_name}"
        info = mask_file_name.split("_")[0].split(",")
        
        shape_name = info[0]
        file_contents += f"{shapes_to_categories[shape_name]} " 

        if len(info) > 1:
            letter = letters_to_categories[info[1]]
            shape_col = info[2]
            letter_col = info[3]
            file_contents += f"{letter} {shape_col} {letter_col} "

        mask = cv2.imread(mask_path)
        polygon = get_polygon(mask)

        if len(polygon) <= 2:
            if os.getenv("VERBOSE") is not None:
                tqdm.write(f"no polygon found for {mask_path}")
            return 
        normalized_polygon = polygon / np.array([mask.shape[1], mask.shape[0]])
        bounding_box_content = give_normalized_bounding_box(normalized_polygon)

        file_contents += f"{bounding_box_content}\n"

    with open(f"{output_dir}/labels/{split_name}/image{num}.txt", "w") as f:
        f.write(file_contents)
    cv2.imwrite(f"{output_dir}/images/{split_name}/image{num}.png", img)

def main():
    user = os.environ["USER"]
    datagen_dir = os.path.dirname(os.path.abspath(__file__))
    categories_to_shapes = json.load(open(f"{datagen_dir}/shape_name_labels.json","r"))
    categories_to_letter = json.load(open(f"{datagen_dir}/letter_labels.json","r"))
    letter_to_categories = {letter:category for category, letter in categories_to_letter.items()}
    shapes_to_categories = {shape:category for category, shape in categories_to_shapes.items()}

    # for linux
    #input_dir = f"/home/{user}/.local/share/godot/app_userdata/forge-godot/godot_data"
    # for windows (change username)
    input_dir = "/mnt/c/Users/kirva/AppData/Roaming/Godot/app_userdata/forge-godot/godot_data_finalized_unit_test"
    output_dir = f"{datagen_dir}/tile_data"
    os.makedirs(output_dir, exist_ok=True)
    for split_name in ["train", "validation", "test"]:
        os.makedirs(f"{output_dir}/labels/{split_name}", exist_ok=True)
        os.makedirs(f"{output_dir}/images/{split_name}", exist_ok=True)
    num_images = len(os.listdir(f"{input_dir}/images"))

    for i in tqdm(range(num_images)):
        gen_img(i, num_images, input_dir, output_dir, shapes_to_categories, letter_to_categories)
        
if __name__ == "__main__":
    main()

    