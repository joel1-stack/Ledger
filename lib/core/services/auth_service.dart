import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInAnonymously() async {
    return await _auth.signInAnonymously();
  }

  Future<void> linkPhone(String verificationId, String smsCode) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    if (_auth.currentUser == null) {
      await _auth.signInWithCredential(credential);
    } else {
      await _auth.currentUser!.linkWithCredential(credential);
    }
  }

  Future<String> sendOtpAndGetVerificationId(String phone) async {
    final completer = Completer<String>();
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (credential) async {
        if (_auth.currentUser == null) {
          await _auth.signInWithCredential(credential);
        } else {
          await _auth.currentUser!.linkWithCredential(credential);
        }
        completer.complete('auto_verified');
      },
      verificationFailed: (e) {
        completer.completeError(Exception(e.message ?? 'Verification failed'));
      },
      codeSent: (vid, _) {
        completer.complete(vid);
      },
      codeAutoRetrievalTimeout: (vid) {
        if (!completer.isCompleted) completer.complete(vid);
      },
    );
    return completer.future;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}
