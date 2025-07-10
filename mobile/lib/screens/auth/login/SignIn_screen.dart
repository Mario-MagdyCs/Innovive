import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../provider/login_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'forgot_password_screen.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final Color greenColor = const Color(0xFF599A74);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;
  String? _generalError;

Future<void> _loginUser() async {
  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();

  if (!_formKey.currentState!.validate()) return;


  // Reset previous errors
  _emailError = null;
  _passwordError = null;
  _generalError = null;

  // Trigger login via Riverpod
  await ref.read(loginControllerProvider.notifier).signIn(email, password);

  final loginState = ref.read(loginControllerProvider);

  if (!mounted) return;

  if (loginState is AsyncData) {
    Navigator.pushReplacementNamed(context, '/home');
  } else if (loginState is AsyncError) {
    final error = loginState.error;

    String message = 'Login failed. Please try again.';

    if (error is AuthException || error is AuthApiException) {
      final e = error as dynamic;
      message = e.message ?? 'Invalid credentials';
    } else if (error is Exception) {
      message = error.toString().replaceAll('Exception: ', '');
    }

    setState(() {
      if (message.toLowerCase().contains('email')) {
        _emailError = message;
      } else if (message.toLowerCase().contains('password')) {
        _passwordError = message;
      } else {
        _generalError = message;
      }
    });
  }
}

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 24),
                const Text('Login', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                if (_generalError != null) _buildErrorBox(_generalError!),

                _buildEmailField(),
                const SizedBox(height: 16),
                _buildPasswordField(),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                      );
                    },
                    child: const Text("Forgot Password?", style: TextStyle(fontWeight: FontWeight.bold,color:Colors.black)),
                  ),
                ),

                

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: loginState is AsyncLoading ? null : _loginUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: greenColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: loginState is AsyncLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Login", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  ),
                ),

                const SizedBox(height: 20),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text("OR"),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),

                _socialButton('Continue with Facebook', Colors.blue, FontAwesomeIcons.facebookF),
                const SizedBox(height: 10),
                _socialButton('Continue with Google', Colors.red, FontAwesomeIcons.google),
                const SizedBox(height: 10),
                _socialButton('Continue with Apple', Colors.black, FontAwesomeIcons.apple),

                const SizedBox(height: 20),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black),
                    children: [
                      const TextSpan(text: "Don't have an account? "),
                      TextSpan(
                        text: "Register",
                        style: TextStyle(color: greenColor, fontWeight: FontWeight.bold),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => Navigator.pushNamed(context, '/register'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

Widget _buildEmailField() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text("Email"),
      const SizedBox(height: 6),
      TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          hintText: "Email",
          errorText: _emailError,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Color(0xFF599A74), // green border when focused
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return 'Email is required';
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(value.trim())) return 'Enter a valid email';
          return null;
        },
        onChanged: (_) {
          if (_emailError != null) setState(() => _emailError = null);
        },
      ),
    ],
  );
}


Widget _buildPasswordField() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text("Password"),
      const SizedBox(height: 6),
      TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          hintText: "Password",
          errorText: _passwordError,
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Color(0xFF599A74), // green border when focused
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Password is required';
          if (value.length < 6) return 'Password must be at least 6 characters';
          return null;
        },
        onChanged: (_) {
          if (_passwordError != null) setState(() => _passwordError = null);
        },
      ),
    ],
  );
}


  Widget _buildErrorBox(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.red, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _socialButton(String label, Color color, IconData icon) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$label coming soon!')),
          );
        },
        icon: FaIcon(icon, color: color, size: 18),
        label: Text(label, style: const TextStyle(color: Colors.black87, fontSize: 14)),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
