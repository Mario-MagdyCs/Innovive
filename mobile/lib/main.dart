import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/onboarding/splash_screen.dart'; // adjust path if needed
import 'screens/auth/login/SignIn_screen.dart';
import 'screens/auth/register/register_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/projects/projects_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/chatbot/chatbot_page.dart';
import 'screens/Home_screen.dart';
import 'screens/upload_project.dart';
import 'screens/profile/settings_screen.dart'; // Add this import
import 'provider/theme_provider.dart'; // Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Transparent nav bar only (keep top visible)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));

  // Enable edge-to-edge layout
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // ✅ Initialize Supabase
  await Supabase.initialize(
    url: 'https://jdbjbkxbtcnndehqbxzq.supabase.co',       // Replace with your Supabase Project URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpkYmpia3hidGNubmRlaHFieHpxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkwNDkyMzAsImV4cCI6MjA2NDYyNTIzMH0.BD1qx4lKlG1xeIJsRgCIuvjRNI0zHnKBhy8EFaV64e8'
  );

  runApp(const ProviderScope(child: MyApp())); // ✅ Wrap with Riverpod
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    // Update system UI overlay style based on theme
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: themeMode == ThemeMode.dark 
          ? Brightness.light 
          : Brightness.dark,
      systemNavigationBarIconBrightness: themeMode == ThemeMode.dark 
          ? Brightness.light 
          : Brightness.dark,
    ));

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Innovive',
      
      // Theme configuration
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: themeMode,
      
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterScreen(),
        '/profile': (context) => const ProfilePage(),
        '/edit-profile': (context) => const EditProfilePage(),
        '/chatbot': (context) => const ChatbotPage(),
        '/home': (context) => const HomePage(),
        '/upload': (context) => const ScanItemScreen(),
        '/setting': (context) => const SettingsScreen(), // Add this route
        '/projects':(context) => const ProjectsScreen(),
      },
    );
  }
}