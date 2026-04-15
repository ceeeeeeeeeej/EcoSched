import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

class AiChatService {
  final GenerativeModel _model;
  final String _apiKey;

  AiChatService(String apiKey)
      : _apiKey = apiKey,
        _model = GenerativeModel(
          model: 'gemini-2.5-flash',
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

    final GenerateContentResponse response =
        await _model.generateContent(contents);
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

    final GenerateContentResponse response =
        await _model.generateContent(contents);
    final String? text = response.text;
    if (text == null || text.trim().isEmpty) {
      return 'I couldn\'t analyze the photo. Please try again with a clearer image.';
    }
    return text.trim();
  }

  /// Direct REST call variant mirroring the provided curl snippet.
  Future<String> sendQuickTextPrompt(String prompt,
      {String? overrideApiKey}) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent',
    );
    final key = overrideApiKey ?? _apiKey;
    final response = await http.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'X-goog-api-key': key,
      },
      body: jsonEncode(<String, dynamic>{
        'contents': [
          {
            'parts': [
              {
                'text': prompt,
              }
            ],
          },
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Gemini REST call failed: ${response.statusCode} ${response.body}');
    }

    final Map<String, dynamic> payload =
        jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = payload['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('No candidates returned by Gemini.');
    }
    final content = candidates.first['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    final textPart = parts?.firstWhere(
      (part) => part['text'] != null,
      orElse: () => null,
    );
    final text = textPart != null ? textPart['text'] as String? : null;
    if (text == null || text.trim().isEmpty) {
      throw Exception('Gemini returned an empty response.');
    }
    return text.trim();
  }
}
