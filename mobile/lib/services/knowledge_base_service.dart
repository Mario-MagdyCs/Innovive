import 'package:flutter/services.dart';

class KnowledgeBaseService {
  static Future<String> loadKnowledgeBase() async {
    return await rootBundle.loadString('assets/knowledge/knowledgebase.txt');
  }
}
