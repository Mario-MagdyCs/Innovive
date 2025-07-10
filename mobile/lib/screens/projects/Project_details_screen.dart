import 'package:flutter/material.dart';
import '../../models/project_model.dart';

class ProjectDetailPage extends StatelessWidget {
  final ProjectModel project;

  const ProjectDetailPage({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final guide = project.guide!;
    final primaryColor = const Color(0xFF4CAF50);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF333333);
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final shadowColor = Colors.black.withOpacity(isDarkMode ? 0.15 : 0.05);
    final dividerColor = isDarkMode ? Colors.grey.shade700 : Colors.black.withOpacity(0.05);
    final category = project.category.isNotEmpty ? project.category[0] : "Unknown";

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          Stack(
            children: [
              SizedBox(
                height: 280,
                width: double.infinity,
                child: Image.network(
                  project.generatedImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.image, size: 48, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    guide.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildMetaTag(Icons.category, category, primaryColor, isDarkMode),
                      const SizedBox(width: 8),
                      _buildMetaTag(Icons.bar_chart_rounded, guide.level, Colors.orange[700]!, isDarkMode),
                    ],
                  ),
                  
                  const SizedBox(height: 28),
                  _buildSectionTitle("Description"),
                  const SizedBox(height: 12),
                  Text(
                    "This project has been generated based on your selected materials. Below are the needed materials and instructions to recreate it.",
                    style: TextStyle(
                      color: textColor.withOpacity(0.8),
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 32),
                  _buildSectionTitle("You'll Need"),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: guide.materials
                      .map((mat) => _buildMaterialItem(mat.title, mat.description, cardColor, textColor, shadowColor))
                      .toList(),
                  ),

                  const SizedBox(height: 32),
                  _buildSectionTitle("Instructions"),
                  const SizedBox(height: 16),
                  Column(
                    children: List.generate(guide.steps.length, (index) {
                      final step = guide.steps[index];
                      return _buildStepCard(index + 1, step.title, step.description, primaryColor, cardColor, textColor, shadowColor);
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3),
    );
  }

  Widget _buildMetaTag(IconData icon, String text, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(isDarkMode ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildMaterialItem(String name, String quantity, Color cardColor, Color textColor, Color shadowColor) {
    return Container(
      width: 160,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: shadowColor, blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
          if (quantity.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(quantity, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ),
        ],
      ),
    );
  }

  Widget _buildStepCard(int number, String instruction, String tip, Color color, Color cardColor, Color textColor, Color shadowColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: shadowColor, blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text("$number", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(instruction, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.4, color: textColor)),
                  const SizedBox(height: 6),
                  Text(tip, style: TextStyle(fontSize: 13, color: Colors.grey[500], fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}