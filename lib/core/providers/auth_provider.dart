import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sms_autofill/sms_autofill.dart';
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

class PhoneAuthHandler {
  final AuthService _authService;
  PhoneAuthHandler(this._authService);

  String? _verificationId;
  String? _phone;
  StreamSubscription? _smsSubscription;

  /// Starts the waterfall auth flow.
  /// Calls [onAutoVerified] immediately if Play Services verifies the SIM.
  /// Calls [onCodeSent] when SMS is sent (start listening for auto-read).
  /// Calls [onManualOtpNeeded] after 15s if no auto-verify or auto-read worked.
  /// Returns a cleanup function.
  Future<void Function()> startWaterfall({
    required String phone,
    required void Function() onAutoVerified,
    required void Function() onCodeSent,
    required void Function(String verificationId) onManualOtpNeeded,
  }) async {
    _phone = phone;
    bool completed = false;

    final timeout = Timer(const Duration(seconds: 15), () {
      if (!completed && _verificationId != null) {
        completed = true;
        onManualOtpNeeded(_verificationId!);
      }
    });

    await _authService.sendOTP(
      phone,
      onCodeSent: (verificationId) {
        _verificationId = verificationId;
        if (!completed) {
          onCodeSent();
          _listenForSmsCode(phone, () {
            if (!completed) {
              completed = true;
              timeout.cancel();
              onAutoVerified();
            }
          });
        }
      },
      onAutoVerified: () {
        if (!completed) {
          completed = true;
          timeout.cancel();
          onAutoVerified();
        }
      },
    );

    return () {
      completed = true;
      timeout.cancel();
      _smsSubscription?.cancel();
    };
  }

  void _listenForSmsCode(String phone, void Function() onCodeReceived) {
    _smsSubscription?.cancel();
    SmsAutoFill().listenForCode();
    _smsSubscription = SmsAutoFill().code.listen((code) {
      if (code.length >= 6) {
        final smsCode = code.replaceAll(RegExp(r'\D'), '');
        if (smsCode.length >= 6) {
          _verifyWithCode(smsCode.substring(0, 6), phone, onCodeReceived);
        }
      }
    });
  }

  Future<void> _verifyWithCode(String code, String phone, void Function() onSuccess) async {
    try {
      if (_verificationId == null) return;
      if (_verificationId!.startsWith('bypass_')) {
        await _authService.bypassSignIn(phone);
      } else {
        await _authService.verifyOTP(_verificationId!, code);
      }
      onSuccess();
    } catch (_) {}
  }

  Future<UserCredential> verifyOTP(String code) async {
    if (_verificationId == null) throw Exception('No verification ID');
    if (_verificationId!.startsWith('bypass_')) {
      return await _authService.bypassSignIn(_phone ?? code);
    }
    return await _authService.verifyOTP(_verificationId!, code);
  }

  void dispose() {
    _smsSubscription?.cancel();
  }
}

final phoneAuthProvider = Provider<PhoneAuthHandler>((ref) => PhoneAuthHandler(ref.read(authServiceProvider)));
