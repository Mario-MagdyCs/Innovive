import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../provider/reset_password_provider.dart';
import 'new_password_screen.dart';

class VerifyCodeScreen extends ConsumerStatefulWidget {
  final String email;
  const VerifyCodeScreen({super.key, required this.email});

  @override
  ConsumerState<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends ConsumerState<VerifyCodeScreen> {
  String _code = "";
  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _verify() async {
    final resetService = ref.read(resetPasswordProvider);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      bool isVerified = await resetService.verifyResetCode(widget.email, _code);

      if (isVerified) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NewPasswordScreen(email: widget.email)),
        );
      } else {
        setState(() {
          _errorMessage = "Invalid code. Please try again.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Verification failed. Please try again.";
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color greenColor = const Color(0xFF5A9B79);
    final Color lightBackground = const Color(0xFFFDFBFA);
    final Size screenSize = MediaQuery.of(context).size;
    final double cardWidth = screenSize.width > 500 ? 400 : screenSize.width * 0.9;

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: lightBackground,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          "Verify Code",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: cardWidth,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Enter the 6-digit code sent to your email.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 30),
                  PinCodeTextField(
                    length: 6,
                    appContext: context,
                    keyboardType: TextInputType.number,
                    animationType: AnimationType.fade,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(12),
                      fieldHeight: 50,
                      fieldWidth: 50,
                      inactiveFillColor: Colors.white,
                      activeFillColor: Colors.white,
                      selectedFillColor: Colors.white,
                      inactiveColor: Colors.grey.shade400,
                      selectedColor: greenColor,
                      activeColor: greenColor,
                    ),
                    animationDuration: const Duration(milliseconds: 300),
                    enableActiveFill: true,
                    onChanged: (value) {
                      _code = value;
                    },
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: greenColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: _isLoading ? null : _verify,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Verify", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.white)),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 20),
                    Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
