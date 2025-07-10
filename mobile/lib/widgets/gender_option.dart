import 'package:flutter/material.dart';

class GenderOption extends StatelessWidget {
  final String option;
  final String selected;
  final VoidCallback onTap;

  const GenderOption({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = option == selected;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Adaptive colors
    final selectedFillColor = isDarkMode
    ? const Color(0xFF263326)  // dark mode selected fill
    : const Color(0xFFE8F5E9); // light mode selected fill
    final Color unselectedFillColor = isDarkMode 
        ? Theme.of(context).cardColor 
        : Colors.grey[100]!;

    final Color selectedBorderColor = const Color(0xFF4CAF50);
    final Color unselectedBorderColor = isDarkMode 
        ? Colors.grey.shade600 
        : Colors.grey.shade400;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? selectedFillColor : unselectedFillColor,
            border: Border.all(
              color: isSelected ? selectedBorderColor : unselectedBorderColor,
              width: 1.2,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2))]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? selectedBorderColor : Colors.grey,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                option,
                style: TextStyle(
                  color: isSelected ? selectedBorderColor : Colors.grey,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
