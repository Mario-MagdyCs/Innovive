import 'package:flutter/material.dart';
import 'welcome_screen.dart';

class OnboardingScreen3 extends StatelessWidget {
  const OnboardingScreen3({super.key});

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Scaffold(
      backgroundColor: Color(0xFF599A74),
      body: Stack(
        children: [
          // Background image
          SizedBox.expand(
            child: Image.asset(
              isLandscape
                  ? 'assets/thirdpage - Copy.png'
                  : 'assets/thirdpage.png',
              fit: isLandscape ? BoxFit.contain : BoxFit.cover,
              alignment: Alignment.topLeft,
            ),
          ),
          // Bottom progress bar + Done button
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Full progress bar (100%)
                Container(
                  width: 200,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                // Done button
                SizedBox(
                  width: 120,
                  child: ElevatedButton(
                     onPressed: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => const WelcomeScreen(),
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
                      "Done",
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
