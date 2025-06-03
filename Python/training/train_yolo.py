from ultralytics import YOLO

# Load a model
model = YOLO("Python/trained_yolo11n.pt")  # lod a pretrained model (recommended for training)

data_dir = "/home/forge/.local/share/godot/app_userdata/forge-godot/godot_data_1746411300/yolo/dataset_config.yaml "
# data_path = "\\home\\forge\\.local\\share\\godot\\app_userdata\\forge-godot\\godot_data_1730860334\\yolo\\dataset_config.yaml"
results = model.train(data=data_dir, epochs=200, imgsz=640)
