import 'package:cloud_firestore/cloud_firestore.dart';
import '../enums/member_role.dart';

class MemberModel {
  final String id;
  final String? userId;
  final String phone;
  final String name;
  final MemberRole role;
  final String groupId;
  final int memberNumber;
  final String status;
  final DateTime joinedAt;

  MemberModel({
    required this.id,
    this.userId,
    required this.phone,
    required this.name,
    required this.role,
    required this.groupId,
    required this.memberNumber,
    this.status = 'active',
    required this.joinedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'phone': phone,
      'name': name,
      'role': role.name,
      'groupId': groupId,
      'memberNumber': memberNumber,
      'status': status,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }

  factory MemberModel.fromMap(Map<String, dynamic> map, String id) {
    return MemberModel(
      id: id,
      userId: map['userId'],
      phone: map['phone'] ?? '',
      name: map['name'] ?? '',
      role: MemberRole.fromString(map['role'] ?? 'member'),
      groupId: map['groupId'] ?? '',
      memberNumber: map['memberNumber'] ?? 0,
      status: map['status'] ?? 'active',
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
