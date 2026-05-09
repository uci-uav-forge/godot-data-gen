import cv2
import os
import tkinter as tk
from tkinter import filedialog
from pathlib import Path

CLASS_NAMES = {0: "tent", 1: "mannequin"}
CLASS_COLORS = {0: (0, 255, 0), 1: (0, 0, 255)}  # green=tent, red=mannequin

def pick_yolo_folder():
    root = tk.Tk()
    root.withdraw()
    folder = filedialog.askdirectory(title="Select YOLO dataset folder (contains images/ and labels/)")
    root.destroy()
    return Path(folder) if folder else None

def get_split(yolo_dir):
    for split in ["train", "validation", "test"]:
        img_dir = yolo_dir / "images" / split
        if img_dir.exists() and any(img_dir.glob("*.png")):
            return split
    return None

def draw_boxes(img, label_path, img_w, img_h):
    if not label_path.exists():
        return img
    with open(label_path) as f:
        for line in f:
            parts = line.strip().split()
            if len(parts) < 5:
                continue
            class_id = int(parts[0])
            x_center, y_center, bw, bh = map(float, parts[1:5])

            x1 = int((x_center - bw / 2) * img_w)
            y1 = int((y_center - bh / 2) * img_h)
            x2 = int((x_center + bw / 2) * img_w)
            y2 = int((y_center + bh / 2) * img_h)

            color = CLASS_COLORS.get(class_id, (255, 255, 0))
            label = CLASS_NAMES.get(class_id, str(class_id))

            cv2.rectangle(img, (x1, y1), (x2, y2), color, 2)
            cv2.putText(img, label, (x1, max(y1 - 6, 10)),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.55, color, 2)
    return img

def main():
    print("Select your YOLO dataset folder...")
    yolo_dir = pick_yolo_folder()
    if not yolo_dir:
        print("No folder selected. Exiting.")
        return

    split = get_split(yolo_dir)
    if not split:
        print(f"No images found in {yolo_dir}/images/train|validation|test")
        return

    img_dir = yolo_dir / "images" / split
    label_dir = yolo_dir / "labels" / split
    images = sorted(img_dir.glob("*.png"))

    if not images:
        print("No PNG images found.")
        return

    print(f"Found {len(images)} images in '{split}' split.")
    print("Controls: [any key] next image | [q] quit")

    for image_path in images:
        label_path = label_dir / (image_path.stem + ".txt")
        img = cv2.imread(str(image_path))
        if img is None:
            continue

        h, w = img.shape[:2]
        img = draw_boxes(img, label_path, w, h)

        # overlay filename and split
        cv2.putText(img, f"{image_path.name} [{split}]", (10, 20),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)

        cv2.imshow("YOLO Verify", img)
        key = cv2.waitKey(0) & 0xFF
        if key == ord('q'):
            break

    cv2.destroyAllWindows()
    print("Done.")

if __name__ == "__main__":
    main()