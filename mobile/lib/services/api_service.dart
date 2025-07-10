import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/guide_model.dart';

class ApiService {
  static const String _baseIp = '192.168.1.31';

  /// Convert file to base64 string with image prefix
  static Future<String> convertFileToBase64(File file) async {
    final bytes = await file.readAsBytes();
    return 'data:image/png;base64,${base64Encode(bytes)}';
  }

  /// Classify base64 image and return list of materials
  static Future<List<String>> classifyImage(String base64Image) async {
    final res = await http.post(
      Uri.parse("http://$_baseIp:5000/classify-base64"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"image": base64Image}),
    );

    if (res.statusCode != 200) {
      throw Exception("Classification failed: ${res.body}");
    }

    final result = jsonDecode(res.body);
    return List<String>.from(result['results'] ?? []);
  }

  /// Generate prompt for given materials and image
  static Future<String> generatePrompt(
    List<String> materials,
    String base64Image,
  ) async {
    final res = await http.post(
      Uri.parse("http://$_baseIp:5003/generate-prompt"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"materials": materials, "base64_image": base64Image}),
    );

    if (res.statusCode != 200) {
      throw Exception("Prompt generation failed: ${res.body}");
    }

    return jsonDecode(res.body)['prompt'];
  }

  /// Generate an image based on prompt and base64 input image
  static Future<String> generateImage(
    String prompt,
    String base64Image,
    bool preserving,
  ) async {
    final port = preserving ? "5006" : "5005";
    final suffix = preserving ? "-base64" : "";

    final res = await http.post(
      Uri.parse("http://$_baseIp:$port/generate-replicate$suffix"),
      headers: {'Content-Type': 'application/json', 'X-Client-Type': 'mobile'},
      body: jsonEncode({"prompt": prompt, "image": base64Image}),
    );

    if (res.statusCode != 200) {
      throw Exception("Image generation failed: ${res.body}");
    }

    final data = jsonDecode(res.body);
    return data['url'] ?? '';
  }

  static Future<String> downloadImageAndConvertToBase64(String imageUrl) async {
    final response = await HttpClient().getUrl(Uri.parse(imageUrl));
    final downloadedImage = await response.close();
    final bytes = await consolidateHttpClientResponseBytes(downloadedImage);
    return 'data:image/png;base64,${base64Encode(bytes)}';
  }

  /// Generate full instruction set
  static Future<GuideModel> generateInstructions(String base64Image) async {
    final res = await http.post(
      Uri.parse("http://$_baseIp:5003/generate-instructions"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"image": base64Image}),
    );

    if (res.statusCode != 200) {
      final err = jsonDecode(res.body);
      throw Exception(err["error"] ?? "Failed to generate instructions");
    }

    final data = jsonDecode(res.body);
    return GuideModel.fromJson(data);
  }

  /// Clarify a specific instruction step
  static Future<String> clarifyStep(
    String projectName,
    int stepNumber,
    String stepTitle,
    String stepDescription,
  ) async {
    final res = await http.post(
      Uri.parse("http://$_baseIp:5003/clarify-step"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "project_name": projectName,
        "step_number": stepNumber,
        "step_title": stepTitle,
        "step_description": stepDescription,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception("Clarification failed: ${res.body}");
    }

    final data = jsonDecode(res.body);
    return data['text'] ?? "No clarification available.";
  }
}
