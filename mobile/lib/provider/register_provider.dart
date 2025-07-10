import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/screens/auth/register/register_controller.dart';

final registerControllerProvider =
    StateNotifierProvider<RegisterController, AsyncValue<void>>(
  (ref) => RegisterController(),
);
