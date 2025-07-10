import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/screens/auth/login/login_controller.dart';

final loginControllerProvider =
    StateNotifierProvider<LoginController, AsyncValue<void>>(
  (ref) => LoginController(),
);
