import 'package:google_generative_ai/google_generative_ai.dart';

class AiChatService {
  final GenerativeModel _model;

  AiChatService(String apiKey)
      : _model = GenerativeModel(
          model: 'gemini-2.0-flash',
          apiKey: apiKey,
          systemInstruction: Content.text(
            'You are EcoSched Assistant for Tago, Surigao del Sur, Philippines. '
            'Detect the user\'s language (English, Filipino/Tagalog, Cebuano/Bisaya, or Tandaganon) and '
            'reply in the same language. Keep answers to 1–2 short, specific sentences focused on municipal '
            'waste management: collection schedules, segregation rules, pickup requests, reporting missed '
            'pickups, drop-off points, and local contacts. If the question is not about waste management or '
            'Tago, ask for a waste-related question for Tago. When replying in Cebuano/Bisaya or Tandaganon, '
            'use clear local terms and simple phrasing.',
          ),
          generationConfig: GenerationConfig(
            temperature: 0.2,
            topP: 0.9,
            topK: 40,
            maxOutputTokens: 120,
          ),
        );

  Future<String> sendMessage(String message, {List<Content>? history}) async {
    final List<Content> contents = <Content>[];
    if (history != null && history.isNotEmpty) {
      contents.addAll(history);
    }
    contents.add(Content.text(message));

    final GenerateContentResponse response = await _model.generateContent(contents);
    final String? text = response.text;
    if (text == null || text.trim().isEmpty) {
      return 'I couldn\'t generate a response. Please try again.';
    }
    return text.trim();
  }

  Future<String> sendMessageWithImages(
    String message,
    List<DataPart> images, {
    List<Content>? history,
  }) async {
    final List<Content> contents = <Content>[];
    if (history != null && history.isNotEmpty) {
      contents.addAll(history);
    }
    final List<Part> parts = <Part>[TextPart(message), ...images];
    contents.add(Content.multi(parts));

    final GenerateContentResponse response = await _model.generateContent(contents);
    final String? text = response.text;
    if (text == null || text.trim().isEmpty) {
      return 'I couldn\'t analyze the photo. Please try again with a clearer image.';
    }
    return text.trim();
  }
}


