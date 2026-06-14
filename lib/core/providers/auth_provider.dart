import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final bypassUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authServiceProvider).bypassUser;
});

final isBypassModeProvider = Provider<bool>((ref) {
  return ref.watch(authServiceProvider).isBypassMode;
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
  String? _phone;

  Future<void> sendOTP(String phone) async {
    _phone = phone;
    await _authService.sendOTP(phone, codeSent: (verificationId, _) {
      _verificationId = verificationId;
    });
  }

  Future<dynamic> verifyOTP(String smsCode) async {
    if (_verificationId == null) throw Exception('No verification ID');
    // Bypass mode: if verificationId starts with 'bypass_', accept any 6-digit code
    if (_verificationId!.startsWith('bypass_')) {
      return true; // Signal that bypass was used
    }
    return await _authService.verifyOTP(_verificationId!, smsCode);
  }
  
  String? get phone => _phone;
  String? get verificationId => _verificationId;
}
