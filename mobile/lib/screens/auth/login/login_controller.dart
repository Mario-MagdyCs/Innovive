import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile/provider/auth_provider.dart';

class LoginController extends StateNotifier<AsyncValue<void>> {
  LoginController() : super(const AsyncData(null));

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();

    try {
      final res = await AuthProvider.signIn(email, password);

      if (res.user == null) {
        throw AuthException('Invalid login credentials');
      }

      state = const AsyncData(null); // ✅ success
    } on AuthException catch (e) {
      state = AsyncError(e, StackTrace.current); // ✅ catch Supabase errors
    } catch (e) {
      state = AsyncError(Exception("Unexpected error"), StackTrace.current); // ✅ fallback error
    }
  }
  // ✅ NEW METHOD for Forgot Password
  Future<void> resetPassword(String email) async {
    state = const AsyncLoading();
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      state = const AsyncData(null);
    } on AuthException catch (e) {
      state = AsyncError(e, StackTrace.current);
    } catch (e) {
      state = AsyncError(Exception("Unexpected error"), StackTrace.current);
    }
  }
}
