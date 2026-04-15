import os
import tensorflow as tf
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.layers import Dense, GlobalAveragePooling2D, Dropout
from tensorflow.keras.models import Model
from PIL import ImageFile

ImageFile.LOAD_TRUNCATED_IMAGES = True

IMG_HEIGHT = 160
IMG_WIDTH = 160
BATCH_SIZE = 8
EPOCHS = 15

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATASET_DIR = BASE_DIR

def train_model():

    datagen = ImageDataGenerator(
        rescale=1./255,
        validation_split=0.2,
        rotation_range=20,
        zoom_range=0.2,
        horizontal_flip=True
    )

    train_generator = datagen.flow_from_directory(
        DATASET_DIR,
        target_size=(IMG_HEIGHT, IMG_WIDTH),
        batch_size=BATCH_SIZE,
        class_mode='categorical',
        subset='training'
    )

    val_generator = datagen.flow_from_directory(
        DATASET_DIR,
        target_size=(IMG_HEIGHT, IMG_WIDTH),
        batch_size=BATCH_SIZE,
        class_mode='categorical',
        subset='validation'
    )

    base_model = MobileNetV2(
        weights='imagenet',
        include_top=False,
        input_shape=(IMG_HEIGHT, IMG_WIDTH, 3)
    )

    base_model.trainable = False

    x = base_model.output
    x = GlobalAveragePooling2D()(x)
    x = Dense(128, activation='relu')(x)
    x = Dropout(0.3)(x)
    outputs = Dense(train_generator.num_classes, activation='softmax')(x)

    model = Model(inputs=base_model.input, outputs=outputs)

    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=0.0001),
        loss='categorical_crossentropy',
        metrics=['accuracy']
    )

    print("\nTraining started...\n")

    model.fit(
        train_generator,
        validation_data=val_generator,
        epochs=EPOCHS
    )

    model.save("garbage_classifier.h5")

    print("\n✅ Training complete!")

if __name__ == '__main__':
    train_model()