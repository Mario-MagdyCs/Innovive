import 'dart:io';
import 'package:flutter/material.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSendPressed;
  final VoidCallback onAttachPressed;
  final bool isListening;
  final VoidCallback onMicToggle;
  final File? pendingImage;
  final VoidCallback onRemoveImage;
  final Color greenColor;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSendPressed,
    required this.onAttachPressed,
    required this.isListening,
    required this.onMicToggle,
    required this.pendingImage,
    required this.onRemoveImage,
    this.greenColor = const Color(0xFF4CAF50),
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scaffoldColor,
        border: Border(
          top: BorderSide(
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pendingImage != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        pendingImage!,
                        width: 70,
                        height: 70,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: onRemoveImage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(3),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.add_circle_outline, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                onPressed: onAttachPressed,
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? cardColor : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          style: const TextStyle(fontFamily: 'Roboto', fontSize: 16),
                          decoration: const InputDecoration(
                            hintText: 'Message...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          maxLines: 5,
                          minLines: 1,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isListening ? Icons.mic : Icons.mic_none,
                          color: isListening ? greenColor : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                        ),
                        onPressed: onMicToggle,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: greenColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: onSendPressed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
