import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ExternalAiService {
  // The FastAPI endpoint hosted on Render
  final String _apiUrl = 'https://ecosched-garbage-classifier.onrender.com/predict';

  /// Classifies an image using the external MobileNet CNN API on Render.
  Future<Map<String, dynamic>> classifyImage(Uint8List imageBytes, {Duration? timeout}) async {
    try {
      if (kDebugMode) print('☁️ [External AI] Sending image to Render API...');
      
      final request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
      request.files.add(
        http.MultipartFile.fromBytes(
          'image', // Changed from 'file' to match server expectations
          imageBytes,
          filename: 'image.jpg',
        ),
      );

      // Use provided timeout or default to 45s (Render spin-up time)
      final streamedResponse = await request.send().timeout(timeout ?? const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        // Map 'class' from server to 'label' for app compatibility
        final String label = data['class'] ?? data['label'] ?? 'Unrecognized';
        final num confidence = data['confidence'] ?? 0.0;
        
        if (kDebugMode) print('☁️ [External AI] Result: $label ($confidence)');
        return {'label': label, 'confidence': confidence};
      } else {
        throw Exception('Cloud API failed with status: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ [External AI] Error: $e');
      return {'label': 'Error: $e', 'confidence': 0.0};
    }
  }

  /// Maps specific training labels to the general EcoSched waste categories.
  String mapLabelToCategory(String rawLabel) {
    final label = rawLabel.toLowerCase().trim();
    
    // Direct matches from your specific training set
    if (label.contains('biodegradable')) return 'Biodegradable';
    if (label.contains('recyclable')) return 'Non-Biodegradable (Recyclable)';
    if (label.contains('non-biodegradable')) return 'Non-Biodegradable (Residual)';
    
    // Material fallbacks (for broader classification)
    if (label.contains('plastic')) return 'Non-Biodegradable (Recyclable)';
    if (label.contains('glass')) return 'Non-Biodegradable (Recyclable)';
    if (label.contains('metal')) return 'Non-Biodegradable (Recyclable)';
    if (label.contains('paper')) return 'Non-Biodegradable (Recyclable)';
    if (label.contains('cardboard')) return 'Non-Biodegradable (Recyclable)';
    
    if (label.contains('food')) return 'Biodegradable';
    if (label.contains('organic')) return 'Biodegradable';
    if (label.contains('leaf')) return 'Biodegradable';
    if (label.contains('wood')) return 'Biodegradable';
    
    if (label.contains('sachet')) return 'Non-Biodegradable (Residual)';
    if (label.contains('diaper')) return 'Non-Biodegradable (Residual)';
    if (label.contains('napkin')) return 'Non-Biodegradable (Residual)';
    if (label.contains('styrofoam')) return 'Non-Biodegradable (Residual)';
    
    if (label.contains('hazardous')) return 'Hazardous';
    if (label.contains('medical')) return 'Hazardous';
    if (label.contains('battery')) return 'Hazardous';
    
    return 'Unrecognized';
  }
}
