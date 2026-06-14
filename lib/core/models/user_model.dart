import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String phone;
  final String name;
  final String? photoUrl;
  final List<String> groupIds;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.phone,
    required this.name,
    this.photoUrl,
    required this.groupIds,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phone': phone,
      'name': name,
      'photoUrl': photoUrl,
      'groupIds': groupIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      phone: map['phone'] ?? '',
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'],
      groupIds: List<String>.from(map['groupIds'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
