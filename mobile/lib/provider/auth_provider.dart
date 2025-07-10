import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider {
  static final _client = Supabase.instance.client;

  // ----------------- Email/Password Sign In -----------------
  static Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  // ----------------- Email/Password Sign Up -----------------
  static Future<AuthResponse> signUp(String email, String password) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  // ----------------- Insert User Profile after Email Registration -----------------
  static Future<void> insertUser({
    required String uid,
    required String email,
    required String fullName,
    required String phone,
    required String gender,
  }) async {
    await _client.from('users').insert({
      'id': uid,
      'email': email,
      'full_name': fullName,
      'phone': phone.isNotEmpty ? phone : null,
      'gender': gender.isNotEmpty ? gender : null,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ----------------- Insert User Profile after Google OAuth -----------------
  static Future<void> handleOAuthProfileInsert(User user) async {
    final profile = await _client
        .from('users')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (profile == null) {
      await _client.from('users').insert({
        'id': user.id,
        'email': user.email,
        'full_name': user.userMetadata?['full_name'] ?? '',
        'phone': null, // ✅ Use null for optional fields
        'gender': null, // ✅ Avoid constraint violation
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }
}
