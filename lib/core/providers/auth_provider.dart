import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authServiceProvider).currentUser;
});

final anonymousAuthProvider = FutureProvider.autoDispose<void>((ref) async {
  final auth = ref.read(authServiceProvider);
  if (auth.currentUser == null) {
    await auth.signInAnonymously();
  }
});
