import os
import tensorflow as tf
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.layers import Dense, GlobalAveragePooling2D, Dropout
from tensorflow.keras.models import Model
import numpy as np

# ==========================================
# 1. Configuration & Hyperparameters
# ==========================================
IMG_HEIGHT = 224
IMG_WIDTH = 224
BATCH_SIZE = 32
EPOCHS = 10
DATASET_DIR = "dataset" # Place your image folders inside here
MODEL_SAVE_PATH = "ecosched_cnn.h5"
TFLITE_SAVE_PATH = "ecosched_cnn.tflite"
LABELS_SAVE_PATH = "labels.txt"

def train_model():
    print("Checking for dataset directory...")
    if not os.path.exists(DATASET_DIR):
        print(f"Error: Dataset directory '{DATASET_DIR}' not found!")
        print("Please create a folder named 'dataset' and inside of it, create subfolders for each category (e.g., 'dataset/Biodegradable', 'dataset/Recyclable'). Put your training images inside those category folders.")
        return

    # ==========================================
    # 2. Data Loading & Augmentation
    # ==========================================
    # We use ImageDataGenerator to slightly modify images while training
    # (rotate, flip, zoom) so the model doesn't just memorize the exact pictures.
    datagen = ImageDataGenerator(
        rescale=1./255,          # Normalize pixels from 0-255 to 0-1
        validation_split=0.2,    # Reserve 20% of images for testing accuracy
        rotation_range=20,
        width_shift_range=0.2,
        height_shift_range=0.2,
        horizontal_flip=True,
        zoom_range=0.2
    )

    print("\nLoading Training Data...")
    train_generator = datagen.flow_from_directory(
        DATASET_DIR,
        target_size=(IMG_HEIGHT, IMG_WIDTH),
        batch_size=BATCH_SIZE,
        class_mode='categorical',
        subset='training'
    )

    print("\nLoading Validation Data...")
    validation_generator = datagen.flow_from_directory(
        DATASET_DIR,
        target_size=(IMG_HEIGHT, IMG_WIDTH),
        batch_size=BATCH_SIZE,
        class_mode='categorical',
        subset='validation'
    )

    if train_generator.samples == 0:
        print("No images found! Make sure you put images inside the category subfolders.")
        return

    # Save the labels file for the Flutter App
    labels = (train_generator.class_indices)
    labels = dict((v,k) for k,v in labels.items())
    with open(LABELS_SAVE_PATH, 'w') as f:
        for i in range(len(labels)):
            f.write(f"{labels[i]}\n")
    print(f"\nSaved class labels to {LABELS_SAVE_PATH}: {labels}")

    # ==========================================
    # 3. Build the Network Architecture
    # ==========================================
    # Transfer Learning: We load MobileNetV2 (a very fast pre-trained model)
    # but we discard its top layer because we want it to classify OUR garbage categories,
    # not its default 1000 internet objects.
    base_model = MobileNetV2(
        weights='imagenet', 
        include_top=False, 
        input_shape=(IMG_HEIGHT, IMG_WIDTH, 3)
    )

    # Freeze the base model so we don't destroy its pre-learned edge/shape detection
    base_model.trainable = False

    # Add our custom classification layers on top
    x = base_model.output
    x = GlobalAveragePooling2D()(x)
    x = Dropout(0.2)(x) # Prevent overfitting
    predictions = Dense(train_generator.num_classes, activation='softmax')(x)

    model = Model(inputs=base_model.input, outputs=predictions)

    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
        loss='categorical_crossentropy',
        metrics=['accuracy']
    )

    # ==========================================
    # 4. Train the Model
    # ==========================================
    print("\nStarting Training...")
    history = model.fit(
        train_generator,
        epochs=EPOCHS,
        validation_data=validation_generator
    )

    # Save the standard Keras model
    model.save(MODEL_SAVE_PATH)
    print(f"\nStandard Model saved to {MODEL_SAVE_PATH}")

    # ==========================================
    # 5. Convert to TFLite (For Mobile App)
    # ==========================================
    print("Converting model to TensorFlow Lite format for Flutter...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    tflite_model = converter.convert()

    with open(TFLITE_SAVE_PATH, 'wb') as f:
        f.write(tflite_model)
    
    print(f"\n==========================================")
    print(f"SUCCESS! TFLite model saved to: {TFLITE_SAVE_PATH}")
    print(f"==========================================")
    print("Next Steps:")
    print(f"1. Copy {TFLITE_SAVE_PATH} to your Flutter project's 'assets/models/' folder.")
    print(f"2. Copy {LABELS_SAVE_PATH} to your Flutter project's 'assets/models/' folder.")

if __name__ == '__main__':
    train_model()
