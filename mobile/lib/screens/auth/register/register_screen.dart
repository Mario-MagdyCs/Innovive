import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../provider/register_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../provider/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final Color greenColor = const Color(0xFF599A74);

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  String selectedGender = 'Male';
  bool isChecked = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? emailError;
  String? generalError;

  Future<void> _registerUser() async {
    final email = emailController.text.trim();
    final password = passController.text.trim();
    final fullName = fullNameController.text.trim();

    if (!_formKey.currentState!.validate()) return;

    if (!isChecked) {
      setState(() => generalError = "Please accept the terms and privacy policy.");
      return;
    }

    emailError = null;
    generalError = null;

    await ref.read(registerControllerProvider.notifier).register(
      email: email,
      password: password,
      fullName: fullName,
      phone: phoneController.text.trim(),
      gender: selectedGender,
    );

    final registerState = ref.read(registerControllerProvider);

    if (!mounted) return;

    if (registerState is AsyncData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration successful!"), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else if (registerState is AsyncError) {
      final error = registerState.error;
      String message = 'Registration failed. Please try again.';
      if (error is AuthException || error is AuthApiException) {
        final e = error as dynamic;
        message = e.message ?? 'Invalid input';
      } else {
        message = error.toString().replaceAll('Exception: ', '');
      }

      setState(() {
        if (message.toLowerCase().contains('email')) {
          emailError = message;
        } else {
          generalError = message;
        }
      });
    }
  }

  Future<void> _signInWithGoogle() async {
  try {
    await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.flutter://login-callback',
    );

    // After OAuth completes, ensure profile data exists
    final session = Supabase.instance.client.auth.currentSession;
    final user = session?.user;

    if (user != null) {
      await AuthProvider.handleOAuthProfileInsert(user);
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  } on AuthException catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In failed: ${e.message}')),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passController.dispose();
    confirmController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Register"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 18),
              const Text('Hi, Welcome! 👋', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 18),
              if (generalError != null) _buildErrorBox(generalError!),
              _buildField("Full Name", fullNameController),
              const SizedBox(height: 12),
              _buildPhoneField(),
              const SizedBox(height: 12),
              _buildGenderSelector(),
              const SizedBox(height: 12),
              _buildEmailField(),
              const SizedBox(height: 12),
              _buildPasswordField(
                "Create Password", 
                "Minimum 8 characters", 
                passController, 
                _obscurePassword, 
                () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              const SizedBox(height: 12),
              _buildPasswordField(
                "Confirm Password", 
                "Repeat your password", 
                confirmController, 
                _obscureConfirmPassword, 
                () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Checkbox(
                    value: isChecked,
                    onChanged: (val) => setState(() => isChecked = val ?? false),
                    activeColor: greenColor,
                  ),
                  const Expanded(child: Text("I accept the terms and privacy policy")),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: state is AsyncLoading ? null : _registerUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: greenColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: state is AsyncLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Register", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("OR")),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
              _socialButton(
                'Continue with Facebook',
                Colors.blue,
                FontAwesomeIcons.facebookF,
                onPressed: () async {
                  await Supabase.instance.client.auth.signInWithOAuth(
                    OAuthProvider.facebook,
                    redirectTo: 'io.supabase.flutter://login-callback',
                  );
                },
              ),
              const SizedBox(height: 10),
              _socialButton(
                'Continue with Google',
                Colors.red,
                FontAwesomeIcons.google,
                onPressed: _signInWithGoogle,
              ),
              const SizedBox(height: 10),
              _socialButton(
                'Continue with Apple',
                Colors.black,
                FontAwesomeIcons.apple,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Apple Sign-In coming soon!')),
                  );
                },
              ),
              const SizedBox(height: 20),
              Center(
                child: Text.rich(
                  TextSpan(
                    text: "Already have an account? ",
                    children: [
                      TextSpan(
                        text: 'Login',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF599A74)),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => Navigator.pushReplacementNamed(context, '/login'),
                      ),
                    ],
                  ), 
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        validator: (value) {
          if (value == null || value.trim().isEmpty) return '$label is required';
          return null;
        },
        decoration: InputDecoration(
          hintText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Color(0xFF599A74), // green when focused
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ],
  );
}


  Widget _buildPhoneField() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Phone Number'),
      const SizedBox(height: 6),
      TextFormField(
        controller: phoneController,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          hintText: 'e.g., 01012345678',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Color(0xFF599A74), // green when focused
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return 'Phone number is required';
          if (!RegExp(r'^(01)[0-9]{9}$').hasMatch(value.trim())) return 'Enter a valid Egyptian phone number';
          return null;
        },
        onChanged: (_) {
          if (generalError != null) setState(() => generalError = null);
        },
      ),
    ],
  );
}


  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Gender"),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _genderOption("Male")),
            const SizedBox(width: 8),
            Expanded(child: _genderOption("Female")),
          ],
        ),
      ],
    );
  }

  Widget _genderOption(String gender) {
    final isSelected = selectedGender == gender;
    return GestureDetector(
      onTap: () => setState(() => selectedGender = gender),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? const Color(0xFF4CAF50) : Colors.grey,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              gender,
              style: TextStyle(
                color: isSelected ? const Color(0xFF4CAF50) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Your Email'),
      const SizedBox(height: 6),
      TextFormField(
        controller: emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          hintText: 'Email',
          errorText: emailError,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Color(0xFF599A74), // green when focused
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return 'Email is required';
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) return 'Enter a valid email';
          return null;
        },
        onChanged: (_) {
          if (emailError != null) setState(() => emailError = null);
          if (generalError != null) setState(() => generalError = null);
        },
      ),
    ],
  );
}
  Widget _buildPasswordField(
  String label,
  String hint,
  TextEditingController controller,
  bool obscure,
  VoidCallback toggleObscure,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: (value) {
          if (label.contains("Confirm") && value != passController.text) {
            return 'Passwords do not match';
          }
          if (value == null || value.isEmpty) return 'Password is required';
          if (value.length < 8) return 'Password must be at least 8 characters';
          return null;
        },
        decoration: InputDecoration(
          hintText: hint,
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
            onPressed: toggleObscure,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Color(0xFF599A74), // green when focused
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (_) {
          if (generalError != null) setState(() => generalError = null);
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

  Widget _socialButton(String label, Color color, IconData icon, {VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: FaIcon(icon, color: color, size: 18),
        label: Text(label, style: const TextStyle(color: Colors.black87, fontSize: 14)),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}