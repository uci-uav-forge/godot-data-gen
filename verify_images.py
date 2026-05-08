# PLACE IN YOLO OUTPUT FOLDER!
import cv2
import os
from pathlib import Path

image_dir = Path("images/train")
label_dir = Path("labels/train")

for image_path in image_dir.glob("*.png"):
    label_path = label_dir / (image_path.stem + ".txt")
    if not label_path.exists():
        continue

    img = cv2.imread(str(image_path))
    h, w = img.shape[:2]

    with open(label_path) as f:
        for line in f:
            parts = line.strip().split()
            class_id = int(parts[0])
            x_center, y_center, bw, bh = map(float, parts[1:])

            x1 = int((x_center - bw/2) * w)
            y1 = int((y_center - bh/2) * h)
            x2 = int((x_center + bw/2) * w)
            y2 = int((y_center + bh/2) * h)

            color = (0, 255, 0) if class_id == 0 else (0, 0, 255)
            label = "tent" if class_id == 0 else "mannequin"
            cv2.rectangle(img, (x1, y1), (x2, y2), color, 2)
            cv2.putText(img, label, (x1, y1-5), cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 1)

    cv2.imshow("verify", img)
    key = cv2.waitKey(0)
    if key == ord('q'):
        break

cv2.destroyAllWindows()