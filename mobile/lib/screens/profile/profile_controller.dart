import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/provider/profile_provider.dart';

class ProfileController extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  ProfileController() : super(const AsyncLoading());

  Future<void> loadProfile(String uid) async {
    state = const AsyncLoading();
    try {
      final data = await ProfileProvider.fetchUserProfile(uid);
      state = AsyncData(data ?? {});
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> updates) async {
    try {
      await ProfileProvider.updateUserProfile(uid, updates);
      await loadProfile(uid);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
