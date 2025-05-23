from ultralytics import YOLO
import cv2
import torch

video = "discord_vid.mp4"

model_srcs = ["trained_yolo11n.pt","yolo11n.pt","coco_yolo11n.pt"]

for model_src in model_srcs:
    model = YOLO(model_src)
    results = model(video)  # generator of Results objects
    print(results)
    # print("hi")
    break

