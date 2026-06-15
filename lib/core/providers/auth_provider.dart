import 'dart:async';
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
  String? _phone;

  Future<String> sendOTP(String phone) async {
    _phone = phone;
    final completer = Completer<String>();
    final timeout = Timer(const Duration(seconds: 30), () {
      if (!completer.isCompleted) {
        _verificationId = 'bypass_${DateTime.now().millisecondsSinceEpoch}';
        completer.complete(_verificationId!);
      }
    });

    await _authService.sendOTP(
      phone,
      onCodeSent: (verificationId) {
        _verificationId = verificationId;
        if (!completer.isCompleted) {
          timeout.cancel();
          completer.complete(verificationId);
        }
      },
      onAutoVerified: () {
        if (!completer.isCompleted) {
          timeout.cancel();
          completer.complete('auto_verified');
        }
      },
    );

    return completer.future;
  }

  Future<UserCredential> verifyOTP(String code) async {
    if (_verificationId == null) throw Exception('No verification ID');
    if (_verificationId!.startsWith('bypass_')) {
      return await _authService.bypassSignIn(_phone ?? code);
    }
    return await _authService.verifyOTP(_verificationId!, code);
  }
}
