import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

const String baseUrl = "http://192.168.1.105:5000";

class ResetPasswordService {
  Future<void> sendResetCode(String email) async {
    final response = await http.post(
      Uri.parse("$baseUrl/send-reset-code/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    if (response.statusCode == 200) {
      return;
    } else {
      final data = jsonDecode(response.body);
      final error = data['error'] ?? "Unknown error";
      throw Exception(error);  // throw real error for Flutter to catch
    }
  }

  Future<bool> verifyResetCode(String email, String code) async {
    final response = await http.post(
      Uri.parse("$baseUrl/verify-code/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "code": code}),
    );

    return response.statusCode == 200;
  }

  Future<void> resetPassword(String email, String newPassword) async {
    final response = await http.post(
      Uri.parse("$baseUrl/reset-password/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "new_password": newPassword}),
    );

    if (response.statusCode == 200) {
      return;
    } else {
      final data = jsonDecode(response.body);
      final error = data['error'] ?? "Unknown error";
      throw Exception(error);
    }
  }
}

final resetPasswordProvider = Provider((ref) => ResetPasswordService());
