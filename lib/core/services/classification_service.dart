import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class ClassificationService {
  Interpreter? _interpreter;
  List<String>? _labels;

  static const String modelPath = 'assets/models/garbage_classifier.tflite';
  static const String labelsPath = 'assets/models/labels.txt';

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(modelPath);
      final labelsData = await rootBundle.loadString(labelsPath);
      _labels = labelsData.split('\n').where((s) => s.isNotEmpty).toList();
      print('✅ TFLite Model & Labels loaded successfully');
    } catch (e) {
      print('❌ Error loading TFLite model: $e');
    }
  }

  Future<Map<String, dynamic>> classifyImage(Uint8List imageBytes) async {
    if (_interpreter == null) await loadModel();
    if (_interpreter == null) return {'label': 'Error', 'confidence': 0.0};

    // 1. Preprocess image
    img.Image? originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) return {'label': 'Invalid Image', 'confidence': 0.0};

    // Resize to 160x160 (Custom MobileNetV2 trained shape)
    img.Image resizedImage = img.copyResize(originalImage, width: 160, height: 160);

    // 2. Convert to input tensor [1, 160, 160, 3]
    // mean = 0, std = 255.0 results in 0-1 scaling
    var input = _imageToByteListFloat32(resizedImage, 160, 0, 255.0);

    // 3. Prepare output tensor [1, num_labels]
    var output = List<double>.filled(_labels!.length, 0).reshape([1, _labels!.length]);

    // 4. Run inference
    _interpreter!.run(input, output);


    // 5. Post-process result
    List<double> probabilities = List<double>.from(output[0]);
    int maxIndex = 0;
    double maxProb = -1.0;

    for (int i = 0; i < probabilities.length; i++) {
      if (probabilities[i] > maxProb) {
        maxProb = probabilities[i];
        maxIndex = i;
      }
    }

    return {
      'label': _labels![maxIndex],
      'confidence': maxProb,
    };
  }

  Uint8List _imageToByteListFloat32(
      img.Image image, int inputSize, double mean, double std) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (pixel.r - mean) / std;
        buffer[pixelIndex++] = (pixel.g - mean) / std;
        buffer[pixelIndex++] = (pixel.b - mean) / std;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }

  void dispose() {
    _interpreter?.close();
  }
}
