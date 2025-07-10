import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:mobile/screens/projects/Project_details_screen.dart';

class DIYProjectCard extends StatefulWidget {
  final String title;
  final String description;
  final String imagePath;
  final String level;
  final VoidCallback? onArrowTap;

  const DIYProjectCard({
    super.key,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.level,
    this.onArrowTap,
  });

  @override
  State<DIYProjectCard> createState() => _DIYProjectCardState();
}

class _DIYProjectCardState extends State<DIYProjectCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isHovered = false;
  bool _isFavorited = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _elevationAnimation = Tween<double>(begin: 8.0, end: 20.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: MouseRegion(
            onEnter: (_) {
              setState(() => _isHovered = true);
              _animationController.forward();
            },
            onExit: (_) {
              setState(() => _isHovered = false);
              _animationController.reverse();
            },
            child: Container(
              width: 220,
              height: 310,
              margin: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                    width: 1.2,
                  ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.06),
                    blurRadius: _elevationAnimation.value,
                    offset: Offset(0, _elevationAnimation.value / 3),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image + Favorite icon
                    Stack(
                      children: [
                        SizedBox(
                          height: 180,
                          width: double.infinity,
                          child: _buildImage(widget.imagePath),
                        ),
                        Container(
                          height: 140,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _isFavorited = !_isFavorited);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                _isFavorited
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: Colors.redAccent,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1A1A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: levelColor(widget.level).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    widget.level.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: levelColor(widget.level),
                                    ),
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: _isHovered
                                          ? [
                                              levelColor(widget.level),
                                              levelColor(widget.level).withOpacity(0.8),
                                            ]
                                          : [
                                              levelColor(widget.level).withOpacity(0.1),
                                              levelColor(widget.level).withOpacity(0.05),
                                            ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: _isHovered
                                        ? null
                                        : Border.all(
                                            color: levelColor(widget.level).withOpacity(0.2),
                                            width: 1,
                                          ),
                                  ),
                                  child: GestureDetector(
                                    onTap: widget.onArrowTap,
                                    child: Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 20,
                                      color: _isHovered ? Colors.white : levelColor(widget.level),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ✅ Image loader
  Widget _buildImage(String imagePath) {
    if (imagePath.startsWith('data:image')) {
      final base64Str = imagePath.split(',')[1];
      final decodedBytes = base64Decode(base64Str);
      return Image.memory(decodedBytes, fit: BoxFit.cover);
    } else if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: const Center(child: Icon(Icons.image, size: 48, color: Colors.grey)),
          );
        },
      );
    } else {
      return Container(
        color: Colors.grey[200],
        child: const Center(child: Icon(Icons.image, size: 48, color: Colors.grey)),
      );
    }
  }

  Color levelColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return const Color(0xFF4CAF50);
      case 'intermediate':
        return const Color(0xFFFFA000);
      case 'hard':
        return const Color(0xFFD32F2F);
      default:
        return Colors.grey;
    }
  }
}
