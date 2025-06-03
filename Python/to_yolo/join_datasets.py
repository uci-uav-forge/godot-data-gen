import os
from pathlib import Path



# join godot data and uavf data
# make the uavf data as the test data
# make the godot test to train
# take the yolo fold and put it subfolder of Data


"""
  0: mannequin
  1: suitcase
  2: tennisracket
  3: boat
  4: stopsign
  5: plane
  6: baseballbat
  7: bus
  8: mattress
  9: skis
  10: umbrella
  11: snowboard
  12: motorcycle
  13: car
  14: sportsball

  names: ['skis', 'stopsign', 'suitcase', 'tennisracket']
"""
conv_irl_to_full = {0:'9', 1:'4', 2:'1', 3:'2'}

dir = "Data/irl_test"

labels_files = Path(f"{dir}/valid/labels").glob("*.txt")
# print(len(list(labels_files)))
# dataset_dirs = sorted(list(Path(f"/home/{user}/.local/share/godot/app_userdata/forge-godot").glob('godot_data*')))

n = 0
for file in list(labels_files):
    old = []
    with open(file,"r") as f:
        old = f.readlines()
    if old is not []:
        newlines = []
        for line in old:
            parts = line.strip().split()
            parts[0] = conv_irl_to_full[int(parts[0])]
            newlines.append(" ".join(parts) + "\n")
        with open(file,"w") as f:
            f.writelines(newlines)


