import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/widgets/card_widget.dart';
import '../provider/theme_provider.dart'; // Adjust path as needed

class HomePage extends ConsumerWidget {  // Changed from StatelessWidget
  const HomePage({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {  // Added WidgetRef ref parameter
    bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;  // Get current theme
    
    return Scaffold(
      // Removed backgroundColor - let theme handle it
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.green[400],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.eco, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Innovive',
              style: TextStyle(
                // Use theme-aware text color
                color: Theme.of(context).textTheme.titleLarge?.color,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh, 
              color: Theme.of(context).iconTheme.color, // Theme-aware icon color
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              Icons.logout, 
              color: Theme.of(context).iconTheme.color, // Theme-aware icon color
            ),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 8.0,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  isLandscape
                      ? 'assets/Main_home - Copy.png'
                      : 'assets/Main_home.png',
                  width: double.infinity,
                  height:
                      isLandscape ? screenHeight * 0.6 : screenHeight * 0.25,
                  fit: isLandscape ? BoxFit.contain : BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Progress Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      // Use theme-aware text color
                      color: Theme.of(context).textTheme.headlineSmall?.color,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.green[500]!, Colors.green[700]!],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Waste managed: 4 Kg Co₂',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '25 / 250 points',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.orange[400],
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: 0.1,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Categories Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      // Use theme-aware text color
                      color: Theme.of(context).textTheme.headlineSmall?.color,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'See all',
                      style: TextStyle(
                        color: Colors.green[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Category Grid
            SizedBox(
              height: isLandscape ? 140 : 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 7,
                itemBuilder: (context, index) {
                  final items = [
                    {'title': 'Plastic Bottle', 'path': 'assets/plastic.png'},
                    {'title': 'Glass Bottle', 'path': 'assets/bottle.png'},
                    {'title': 'Paper', 'path': 'assets/paper.png'},
                    {'title': 'Cardboard', 'path': 'assets/box.png'},
                    {'title': 'Glass Jar', 'path': 'assets/glass jar.jpg'},
                    {'title': 'Tin Can', 'path': 'assets/tin can.jpg'},
                    {'title': 'Plastic Cutlery', 'path': 'assets/cutlery.jpg'},
                  ];

                  return _buildCategoryCard(
                    context: context,
                    imagePath: items[index]['path']!,
                    title: items[index]['title']!,
                    onTap: () {},
                    isLandscape: isLandscape,
                    isDarkMode: isDarkMode,
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 12),
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, top: 10),
                    child: Text(
                      'Projects of the Day',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        // Use theme-aware text color
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      height: 320,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: const [
                          DIYProjectCard(
                            title: 'Glass Lamp',
                            description: 'Reused jar',
                            imagePath: 'assets/DIY1.jpg',
                            level: 'Intermediate',
                          ),
                          DIYProjectCard(
                            title: 'Sofa Chair',
                            description: 'Fabric + foam',
                            imagePath: 'assets/DIY1.jpg',
                            level: 'Beginner',
                          ),
                          DIYProjectCard(
                            title: 'Can Storage',
                            description: 'Tin cans project',
                            imagePath: 'assets/DIY1.jpg',
                            level: 'Hard',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          // Use theme-aware background color
          color: Theme.of(context).bottomNavigationBarTheme.backgroundColor ??
                 (isDarkMode ? const Color(0xFF1E1E1E) : Colors.white),
          boxShadow: [
            BoxShadow(
              color: (isDarkMode ? Colors.black : Colors.grey).withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.green[600],
          unselectedItemColor: isDarkMode ? Colors.grey[500] : Colors.grey[400],
          currentIndex: 0,
          onTap: (index) {
            switch (index) {
              case 0:
                break;
              case 1:
                Navigator.pushNamed(context, '/projects');
                break;
              case 2:
                Navigator.pushNamed(context, '/upload');
                break;
              case 3:
                Navigator.pushNamed(context, '/chatbot');
                break;
              case 4:
                Navigator.pushNamed(context, '/profile');
                break;
            }
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.category_outlined),
              activeIcon: Icon(Icons.category),
              label: 'Projects',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[600],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 24),
              ),
              label: '',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.chat_outlined), 
              activeIcon: Icon(Icons.chat), 
              label: 'Chatbot',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required String imagePath,
    required String title,
    required VoidCallback onTap,
    required bool isLandscape,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isLandscape ? 100 : 64,
            height: isLandscape ? 100 : 64,
            margin: const EdgeInsets.only(right: 18),
            decoration: BoxDecoration(
              // Use theme-aware card background
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: (isDarkMode ? Colors.black : Colors.grey).withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(imagePath, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 64,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                // Use theme-aware text color
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}