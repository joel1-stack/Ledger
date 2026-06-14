import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final userProfileProvider = FutureProvider.family<UserModel?, String>((ref, uid) async {
  return ref.watch(authServiceProvider).getUserProfile(uid);
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authServiceProvider).currentUser;
});

final phoneAuthProvider = Provider<PhoneAuthHandler>((ref) => PhoneAuthHandler(ref.read(authServiceProvider)));

class PhoneAuthHandler {
  final AuthService _authService;
  PhoneAuthHandler(this._authService);

  String? _verificationId;

  Future<void> sendOTP(String phone) async {
    await _authService.sendOTP(phone, codeSent: (verificationId, _) {
      _verificationId = verificationId;
    });
  }

  Future<UserCredential> verifyOTP(String smsCode) async {
    if (_verificationId == null) throw Exception('No verification ID');
    return await _authService.verifyOTP(_verificationId!, smsCode);
  }
}
