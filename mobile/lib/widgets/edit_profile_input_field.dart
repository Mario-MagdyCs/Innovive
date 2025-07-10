import 'package:flutter/material.dart';

class EditProfileInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isEditable;
  final bool showEditIcon;
  final VoidCallback? onEditToggle;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;

  const EditProfileInputField({
    super.key,
    required this.label,
    required this.controller,
    this.isEditable = false,
    this.showEditIcon = true,
    this.onEditToggle,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final fieldColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[100];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 16)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: fieldColor,
            border: Border.all(color: Colors.grey.shade700, width: 0.6),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  enabled: isEditable || !showEditIcon,
                  keyboardType: label == "Phone Number"
                      ? TextInputType.phone
                      : (label == "E-mail" ? TextInputType.emailAddress : TextInputType.text),
                  onChanged: onChanged,
                  validator: validator,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (showEditIcon)
                IconButton(
                  icon: Icon(
                    isEditable ? Icons.close : Icons.edit,
                    color: Colors.grey.shade300,
                    size: 20,
                  ),
                  onPressed: onEditToggle,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
