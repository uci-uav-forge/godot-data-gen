# "C:\Users\Bran\AppData\Roaming\Godot\app_userdata\forge-godot\godot_data_1733426593\images"

import os
import sys
import cv2
import numpy as np

def apply_color_augmentation(img):
    """Overlay random shapes (circles and rectangles) on the image."""
    img_copy = img.copy()
    h, w = img.shape[:2]
    n_shapes = np.random.randint(4, 15)

    for _ in range(n_shapes):
        shape = np.random.choice(['circle', 'rectangle'])
        color = tuple(map(int, np.random.randint(0, 255, 3)))
        if shape == 'circle':
            center = np.random.uniform(0, 1, 2)
            radius = np.random.uniform(0.01, 0.3)
            center_px = tuple((center * np.array([w, h])).astype(int))
            cv2.circle(img_copy, center_px, int(radius * w), color, -1)
        elif shape == 'rectangle':
            center = np.random.uniform(0, 1, 2)
            size = np.random.uniform(0.1, 0.3, 2)
            pt1 = ((center - size / 2) * np.array([w, h])).astype(int)
            pt2 = ((center + size / 2) * np.array([w, h])).astype(int)
            cv2.rectangle(img_copy, tuple(pt1), tuple(pt2), color, -1)

    opacity = np.random.uniform(0, 0.7)
    img_out = cv2.addWeighted(img, 1 - opacity, img_copy, opacity, 0)
    return img_out



def save_image(root, file, img):
    """Save augmented image with a new filename. OLDNAME_color.ext """
    filename, ext = os.path.splitext(file)
    new_filename = f"{filename}_color{ext}"
    new_path = os.path.join(root, new_filename)
    cv2.imwrite(new_path, img)

def process_images(folder_path):
    img_ext = ('.png', '.jpg', '.jpeg', '.bmp')
    for dir, _, files in os.walk(folder_path):
        for file in files:
            if not file.lower().endswith(img_ext):
                continue
            path = os.path.join(dir, file)
            img = cv2.imread(path)
            if img is None:
                print(f"Could not load: {path}")
                continue
            try:
                aug = apply_color_augmentation(img)
                save_image(dir, file, aug)
            except Exception as e:
                print(f"Error on {path}: {e}")



if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python augment_color_shapes.py <folder_path>")
        sys.exit(1)

    folder = sys.argv[1]
    if not os.path.isdir(folder):
        print(f"Error: {folder} is not a valid directory.")
        sys.exit(1)

    process_images(folder)
