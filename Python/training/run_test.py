from ultralytics import YOLO

# Load a model
# model = YOLO("yolo11n.pt")  # load an official model
model = YOLO("Data/irl_test/runs/detect/train/weights/best.pt")  # load a custom model

# Validate the model
metrics = model.val(data= "Data/irl_test/dataset_config.yaml", single_cls=True)  # no arguments needed, dataset and settings remembered
# metrics.box.map  # map50-95
# metrics.box.map50  # map50
# metrics.box.map75  # map75
# metrics.box.maps  # a list contains map50-95 of each category
# Data/irl_test/dataset_config.yaml


# video = "discord_vid.mp4"

# model_srcs = ["trained_yolo11n.pt","yolo11n.pt","coco_yolo11n.pt"]

# for model_src in model_srcs:
#     model = YOLO(model_src)
#     results = model(video)  # generator of Results objects
#     print(results)
#     # print("hi")
#     break