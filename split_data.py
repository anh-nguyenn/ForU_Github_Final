import os
import shutil
import random

DATA_FOLDER_PATH = os.path.join("Yoga")
OUTPUT_FOLDER_PATH = os.path.join("Dataset","YogaPose")

folder_list = os.listdir(DATA_FOLDER_PATH)
num_test_file = len(folder_list)*0.1*len(os.listdir(os.path.join(DATA_FOLDER_PATH, folder_list[0])))
num_val_file = len(folder_list)*0.1*len(os.listdir(os.path.join(DATA_FOLDER_PATH, folder_list[0])))
counter1 = 0
counter2 = 0
for folder_name in folder_list:
    file_list = os.listdir(os.path.join(DATA_FOLDER_PATH, folder_name))
    for file in file_list:
        if counter1 < num_test_file or counter2 < num_val_file:
            a = random.randrange(3)
            if a==0 and counter1 < num_test_file:
                counter1 = counter1 + 1
                if not os.path.exists(os.path.join(OUTPUT_FOLDER_PATH,"TEST", folder_name)):
                    os.makedirs(os.path.join(OUTPUT_FOLDER_PATH,"TEST", folder_name))
                shutil.copy(os.path.join(DATA_FOLDER_PATH, folder_name, file), os.path.join(OUTPUT_FOLDER_PATH,"TEST", folder_name))
                continue
            elif a==1 and counter2 < num_test_file:
                counter2 = counter2 + 1
                if not os.path.exists(os.path.join(OUTPUT_FOLDER_PATH,"VAL", folder_name)):
                    os.makedirs(os.path.join(OUTPUT_FOLDER_PATH,"VAL", folder_name))
                shutil.copy(os.path.join(DATA_FOLDER_PATH, folder_name, file), os.path.join(OUTPUT_FOLDER_PATH,"VAL", folder_name))
            else:
                if not os.path.exists(os.path.join(OUTPUT_FOLDER_PATH,"TRAIN", folder_name)):
                    os.makedirs(os.path.join(OUTPUT_FOLDER_PATH,"TRAIN", folder_name))
                shutil.copy(os.path.join(DATA_FOLDER_PATH, folder_name, file), os.path.join(OUTPUT_FOLDER_PATH,"TRAIN", folder_name))
        else:
            if not os.path.exists(os.path.join(OUTPUT_FOLDER_PATH,"TRAIN", folder_name)):
                os.makedirs(os.path.join(OUTPUT_FOLDER_PATH,"TRAIN", folder_name))
            shutil.copy(os.path.join(DATA_FOLDER_PATH, folder_name, file), os.path.join(OUTPUT_FOLDER_PATH,"TRAIN", folder_name))