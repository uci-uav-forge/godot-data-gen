from ultralytics import YOLO
import cv2
import torch

# Load a model
model = YOLO("yolo11n.pt")  # load a pretrained model (recommended for training)

temp = "/home/forge/.local/share/godot/app_userdata/forge-godot/godot_data_1730860334/yolo/dataset_config.yaml"
# data_path = "\\home\\forge\\.local\\share\\godot\\app_userdata\\forge-godot\\godot_data_1730860334\\yolo\\dataset_config.yaml"
results = model.train(data=temp, epochs=100, imgsz=640)
