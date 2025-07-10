import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile/provider/auth_provider.dart';

class RegisterController extends StateNotifier<AsyncValue<void>> {
  RegisterController() : super(const AsyncData(null));

  
Future<void> register({
  required String email,
  required String password,
  required String fullName,
  required String phone,
  required String gender,
}) async {
  state = const AsyncLoading();

  try {
    final res = await AuthProvider.signUp(email, password);

    if (res.user == null) {
      throw AuthException('Registration failed');
    }

    await AuthProvider.insertUser(
      uid: res.user!.id,
      email: email,
      fullName: fullName,
      phone: phone,
      gender: gender,
    );

    state = const AsyncData(null);
  } on AuthException catch (e) {
    state = AsyncError(e, StackTrace.current);
  } catch (e) {
    state = AsyncError(Exception("Unexpected error occurred"), StackTrace.current);
  }
}
}