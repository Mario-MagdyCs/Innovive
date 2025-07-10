import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileProvider {
  static final _client = Supabase.instance.client;

  // ✅ Safely fetch current user profile from the 'users' table
  static Future<Map<String, dynamic>?> fetchUserProfile(String uid) async {
    final response = await _client
        .from('users')
        .select()
        .eq('id', uid)
        .maybeSingle(); // ✅ This is the important fix

    return response;
  }

  // ✅ Update user profile fields
  static Future<void> updateUserProfile(String uid, Map<String, dynamic> updates) async {
    await _client
        .from('users')
        .update(updates)
        .eq('id', uid);
  }
}
