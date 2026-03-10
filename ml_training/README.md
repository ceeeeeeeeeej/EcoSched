# EcoSched Custom Garbage Classification CNN

This folder contains a complete, ready-to-run Python script (`train_model.py`) that uses **TensorFlow** and **Transfer Learning** (MobileNetV2) to train a custom garbage classification model.

Once trained, the script will automatically convert your AI into a lightweight `.tflite` format ready to be loaded directly into your Flutter App!

## Prerequisites

1.  **Install Python** (3.8 or higher)
2.  **Install TensorFlow and Dependencies**:
    Open your terminal/command prompt and run:
    ```bash
    pip install tensorflow scipy pillow numpy
    ```

## Step 1: Prepare Your Dataset
The `train_model.py` script needs pictures of garbage to learn from. We have provided an empty `dataset/` folder for you.

Inside the `dataset/` folder, create subfolders for each category of waste you want the AI to recognize. **The names of these folders will become the exact labels the AI outputs.**

### Example Structure:
```
ml_training/
│
├── train_model.py
└── dataset/
    ├── Biodegradable/      <-- Put 200+ images of food waste, leaves, etc. here
    ├── Recyclable/         <-- Put 200+ images of plastic bottles, cans, etc. here
    ├── Residual/           <-- Put 200+ images of candy wrappers, dirty plastic here
    └── Hazardous/          <-- Put 200+ images of batteries, lightbulbs here
```

> **Tip:** You need at least 150-200 images per folder for the AI to start becoming "smart". The more images, the better it works!

## Step 2: Train the Model

Once your images are sorted into their respective folders:

1.  Open your terminal
2.  Navigate to this `ml_training` directory.
3.  Run the training script:
    ```bash
    python train_model.py
    ```

## Step 3: What Happens Next?
The script will run for several minutes (or longer, depending on your computer's speed and how many images you have). 

Once it finishes, it will generate two new files in this folder:
1.  **`ecosched_cnn.tflite`**: This is your fully trained Artificial Intelligence!
2.  **`labels.txt`**: This tells Flutter which folder corresponds to which output.

You will copy these two files into your Flutter app's `assets/models/` directory, and the app will instantly be able to scan garbage entirely offline without Gemini!
