import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class DropdownsSelector extends StatelessWidget {
  final String selectedModel;
  final ValueChanged<String> onChanged;
  final String selectedLanguage;
  final ValueChanged<String> onLanguageChanged;
  final Map<String, String> languageMap;

  const DropdownsSelector({
    super.key,
    required this.selectedModel,
    required this.onChanged,
    required this.selectedLanguage,
    required this.onLanguageChanged,
    required this.languageMap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: 8),

        const CircleAvatar(
          radius: 18,
          backgroundColor: kGreenColor,
          child: Icon(Icons.eco, size: 20, color: Colors.white),
        ),
        const SizedBox(width: 12),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
           Padding(
              padding: EdgeInsets.only(top: 6), // 👈 adjust the top margin here
              child: const Text(
                "Innovive Assistant",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedModel,
                items: modelOptions.map((model) {
                  return DropdownMenuItem<String>(
                    value: model,
                    child: Text(
                      model,
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) onChanged(value);
                },
                style: const TextStyle(color: kGreenColor, fontWeight: FontWeight.w500),
                icon: const Icon(Icons.arrow_drop_down, color: kGreenColor),
              ),
            ),
          ],
        ),

        const Spacer(),  // THIS IS THE KEY 🔑

        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedLanguage,
            icon: const Icon(Icons.language, color: kGreenColor),
            onChanged: (value) {
              if (value != null) onLanguageChanged(value);
            },
            items: languageMap.entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.value,
                child: Text(entry.key),
              );
            }).toList(),
          ),
        ),

        const SizedBox(width: 8),
      ],
    );

  }
}
