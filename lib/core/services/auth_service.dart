import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  Future<UserModel?> loginWithPhone(String phone) async {
    final snap = await _firestore.collection('users').where('phone', isEqualTo: phone).limit(1).get();
    if (snap.docs.isEmpty) return null;
    _currentUser = UserModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
    return _currentUser;
  }

  Future<UserModel> registerWithPhone(String phone, String name) async {
    final uid = const Uuid().v4();
    _currentUser = UserModel(
      uid: uid,
      phone: phone,
      name: name,
      groupIds: [],
      createdAt: DateTime.now(),
    );
    await _firestore.collection('users').doc(uid).set(_currentUser!.toMap());
    return _currentUser!;
  }

  Future<void> signOut() async {
    _currentUser = null;
  }
}
