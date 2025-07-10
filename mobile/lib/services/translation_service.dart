import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  static const String openAIApiKey = "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";
  static const String apiUrl = 'https://api.openai.com/v1/chat/completions';

  static const languageMapVerbose = {
    'en': 'English',
    'ar': 'Arabic',
    'fr': 'French',
    'de': 'German',
    'es': 'Spanish',
  };

  static Future<String> translateText(String text, String targetLanguageCode) async {
    final targetLanguage = languageMapVerbose[targetLanguageCode] ?? 'English';

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $openAIApiKey',
      },
      body: jsonEncode({
        "model": "gpt-4o",
        "messages": [
          {"role": "system", "content": "You are a translation assistant."},
          {"role": "user", "content": "Translate this text to $targetLanguage: $text"}
        ],
        "max_tokens": 1000,
        "temperature": 0
      }),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return decoded['choices'][0]['message']['content'].trim();
    } else {
      throw Exception('Translation failed: ${response.body}');
    }
  }
}
