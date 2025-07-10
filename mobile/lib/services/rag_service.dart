import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class RagService {
  static const String openAiKey = "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";
  static const String model = 'gpt-4o';

  static Future<String> loadKnowledgeBase() async {
    return await rootBundle.loadString('assets/knowledge/knowledgebase.txt');
  }

static Future<String> queryWithKnowledge(String userMessage) async {
      final knowledge = await loadKnowledgeBase();

      final systemPrompt = '''
    You are Innovive AI assistant.
    You can only answer questions related to Innovive platform and its features.

    Here is Innovive full knowledge base:
    $knowledge

    First:
    - If the question is related to Innovive, answer normally.
    - If the question is unrelated or out of scope, reply only with exactly:
    [IRRELEVANT]

    User Question: "$userMessage"
    ''';

      final response = await http.post(
        Uri.parse("https://api.openai.com/v1/chat/completions"),
        headers: {
          "Authorization": "Bearer $openAiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": model,
          "messages": [
            {"role": "system", "content": systemPrompt},
            {"role": "user", "content": userMessage}
          ],
          "temperature": 0
        }),
      );

      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'].trim();
  }

}
