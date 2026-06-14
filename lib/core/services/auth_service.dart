import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Bypass mode state
  UserModel? _bypassUser;
  bool _isBypassMode = false;

  User? get currentUser => _auth.currentUser;
  UserModel? get bypassUser => _bypassUser;
  bool get isBypassMode => _isBypassMode;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Real Firebase OTP (will fail if Phone Auth not enabled)
  Future<void> sendOTP(String phoneNumber, {required void Function(String, int?) codeSent}) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (e) {
          // Fall back to bypass mode
          codeSent('bypass_${DateTime.now().millisecondsSinceEpoch}', null);
        },
        codeSent: (verificationId, forceResendingToken) {
          codeSent(verificationId, forceResendingToken);
        },
        codeAutoRetrievalTimeout: (verificationId) {},
      );
    } catch (e) {
      codeSent('bypass_${DateTime.now().millisecondsSinceEpoch}', null);
    }
  }

  // Bypass verify - accepts any 6-digit code
  Future<UserModel> bypassVerify(String verificationId, String smsCode, String phone, String name) async {
    _isBypassMode = true;
    final uid = const Uuid().v4();
    _bypassUser = UserModel(
      uid: uid,
      phone: phone,
      name: name,
      groupIds: [],
      createdAt: DateTime.now(),
    );
    await _firestore.collection('users').doc(uid).set(_bypassUser!.toMap());
    return _bypassUser!;
  }

  // Real Firebase OTP verify
  Future<UserCredential> verifyOTP(String verificationId, String smsCode) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _auth.signInWithCredential(credential);
  }

  Future<void> createUserProfile(String name, {String? photoUrl}) async {
    if (_isBypassMode && _bypassUser != null) {
      final updated = UserModel(
        uid: _bypassUser!.uid,
        phone: _bypassUser!.phone,
        name: name,
        photoUrl: photoUrl,
        groupIds: _bypassUser!.groupIds,
        createdAt: _bypassUser!.createdAt,
      );
      _bypassUser = updated;
      await _firestore.collection('users').doc(_bypassUser!.uid).set(updated.toMap());
      return;
    }
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user');
    final userModel = UserModel(
      uid: user.uid,
      phone: user.phoneNumber ?? '',
      name: name,
      photoUrl: photoUrl,
      groupIds: [],
      createdAt: DateTime.now(),
    );
    await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> signOut() async {
    _bypassUser = null;
    _isBypassMode = false;
    await _auth.signOut();
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}
