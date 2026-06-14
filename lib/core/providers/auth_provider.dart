import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authServiceProvider).currentUser;
});
