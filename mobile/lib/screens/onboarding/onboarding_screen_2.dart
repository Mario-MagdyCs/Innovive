import 'package:flutter/material.dart';
import 'onboarding_screen_3.dart';

class OnboardingScreen2 extends StatelessWidget {
  const OnboardingScreen2({super.key});

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Scaffold(
      backgroundColor: Color(0xFF599A74), // fallback in case image doesn't cover
      body: Stack(
        children: [
          // Background image
          SizedBox.expand(
            child: Image.asset(
              isLandscape
                  ? 'assets/secondpage - Copy.png'
                  : 'assets/secondpage.png',
              fit: isLandscape ? BoxFit.contain : BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
  

          // Skip button
          Positioned(
            top: 40,
            right: 20,
            child: TextButton(
              onPressed: () {
                // TODO: Navigate to main app
              },
              child: const Text(
                'Skip',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),

          // Progress bar + Next button
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Progress bar (2/3 full)
                Row(
                  children: [
                    Container(
                      width: 134,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width:6),
                    Container(
                      width: 66,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),

                // Next button
                SizedBox(
                  width: 120,
                  child: ElevatedButton(
                    onPressed: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => const OnboardingScreen3(),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          const begin = Offset(1.0, 0.0); // from right
                          const end = Offset.zero;
                          final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeInOut));
                          return SlideTransition(
                            position: animation.drive(tween),
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: Colors.black26,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    ),
                    child: const Text(
                      "Next",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
