import 'package:flutter/material.dart';
import 'package:mobile/models/instruction_material_model.dart';
import 'package:mobile/models/instruction_step_model.dart';
import '../../models/message_model.dart';
import '../../models/guide_model.dart';
import 'animated_dot.dart';

class ChatMessageBubble extends StatelessWidget {
  final MessageModel message;
  final String selectedLanguage;
  final Future<String> Function(String, String) translateText;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.selectedLanguage,
    required this.translateText,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF333333);
    final bool isUser = message.isUser;
    final bool isImage = message.image != null;
    final bool isNetworkImage = message.networkImage != null;
    final bool isLoading = message.isLoading;
    final double maxWidth = MediaQuery.of(context).size.width * 0.75;
    const greenColor = Color(0xFF4CAF50);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 14,
              backgroundColor: greenColor,
              child: Icon(Icons.eco, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isUser)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 2),
                    child: Text(
                      "Innovive Assistant",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.white : Colors.grey[700],
                      ),
                    ),

                  ),

                if (isImage)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        message.image!,
                        width: 150,
                        height: 150,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                if (isNetworkImage)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        message.networkImage!,
                        width: 150,
                        height: 150,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isUser ? greenColor : cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isLoading
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(3, (i) => AnimatedDot(index: i)),
                        )
                      : message.type == 'instructions'
                          ? FutureBuilder<GuideModel>(
                              future: _translateInstructions(message.data),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return const SizedBox();
                                return _buildInstructions(snapshot.data!, cardColor, textColor, isDarkMode);
                              },
                            )
                          : message.type == 'clarification'
                              ? _buildClarification(message.data['step'], message.data['content'], cardColor, textColor)
                              : Text(
                                  message.text ?? '',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isUser ? Colors.white : textColor,
                                  ),
                                ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Icon(Icons.done_all, size: 14, color: Colors.grey.shade400),
          ],
        ],
      ),
    );
  }

  Future<GuideModel> _translateInstructions(GuideModel data) async {
    if (selectedLanguage == 'en') return data;

    final translatedName = await translateText(data.name, selectedLanguage);
    final translatedLevel = await translateText(data.level, selectedLanguage);
    final translatedMaterials = await Future.wait(data.materials.map((m) async {
      final title = await translateText(m.title, selectedLanguage);
      final desc = await translateText(m.description, selectedLanguage);
      return InstructionMaterial(title: title, description: desc);
    }));
    final translatedSteps = await Future.wait(data.steps.map((s) async {
      final title = await translateText(s.title, selectedLanguage);
      final desc = await translateText(s.description, selectedLanguage);
      return InstructionStep(title: title, description: desc);
    }));

    return GuideModel(name: translatedName, level: translatedLevel, materials: translatedMaterials, steps: translatedSteps);
  }

  Widget _buildInstructions(GuideModel data, Color cardColor, Color textColor, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isDarkMode ? Border.all(color: Colors.grey.shade700, width: 0.8) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[800])),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Difficulty: ', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                data.level,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: _levelColor(data.level),
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1),
          const Text('Materials:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...data.materials.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(fontSize: 15, color: textColor, height: 1.4),
                          children: [
                            TextSpan(text: '${m.title}: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: m.description),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const Divider(height: 24, thickness: 1),
          const Text('Steps:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...data.steps.asMap().entries.map((entry) {
            int idx = entry.key + 1;
            var step = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    alignment: Alignment.topCenter,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.green,
                      child: Text('$idx', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(step.description, style: const TextStyle(fontSize: 14, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildClarification(int stepNumber, String content, Color cardColor, Color textColor) {
    final clarifyTitles = {
      'en': 'Step $stepNumber clarified',
      'ar': 'تم توضيح الخطوة $stepNumber',
      'fr': 'Étape $stepNumber clarifiée',
      'es': 'Paso $stepNumber aclarado',
      'de': 'Schritt $stepNumber geklärt',
    };

    final title = clarifyTitles[selectedLanguage] ?? 'Step $stepNumber clarified';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.search, color: Colors.blue, size: 20),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[700])),
            ],
          ),
          const SizedBox(height: 8),
          Text(content, style: TextStyle(fontSize: 15, height: 1.5, color: textColor)),
        ],
      ),
    );
  }

  Color _levelColor(String level) {
    final normalized = level.toLowerCase().trim().replaceAll('.', '');
    if (normalized == 'beginner') return Colors.green;
    if (normalized == 'intermediate') return Colors.orange;
    return Colors.red;
  }
}
