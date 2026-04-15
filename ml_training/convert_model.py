import tensorflow as tf

# Load trained model
model = tf.keras.models.load_model("garbage_classifier.h5")

# Convert to TFLite
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

# Save file
with open("garbage_classifier.tflite", "wb") as f:
    f.write(tflite_model)

print("✅ TFLite model created: garbage_classifier.tflite")