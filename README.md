# Model-ForU

Classification Model is base on VGG16-CNN model. 

## Team members
1. Tran Que An
2. Nguyen Tuan Anh
3. Dang Huy Phuong
4. Nguyen Hong Quan

## How to train this model
1. Install Deppendecies
```bash
pip install -r requirements.txt
```
2. Download data from https://www.kaggle.com/datasets/shrutisaxena/yoga-pose-image-classification-dataset
3. Split data python3 split_data.py 
```bash
python3 split_data.py 
```
4. Train Model 
```bash
python3 train.py
```

## Pretrained model
We have uploaded a pretrained model of our experiments. You can download the from [Dropbox](https://www.dropbox.com/s/z05hqlh5dovrqk8/VGG16_v2-OCT_Retina_half_dataset.pt?dl=0)
