import 'package:cloud_firestore/cloud_firestore.dart';

class TimelineEventModel {
  final String id;
  final String groupId;
  final String type;
  final String actorMemberId;
  final String actorName;
  final String description;
  final String? targetType;
  final String? targetId;
  final Map<String, dynamic>? snapshot;
  final DateTime createdAt;

  TimelineEventModel({
    required this.id,
    required this.groupId,
    required this.type,
    required this.actorMemberId,
    required this.actorName,
    required this.description,
    this.targetType,
    this.targetId,
    this.snapshot,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'type': type,
      'actorMemberId': actorMemberId,
      'actorName': actorName,
      'description': description,
      'targetType': targetType,
      'targetId': targetId,
      'snapshot': snapshot,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory TimelineEventModel.fromMap(Map<String, dynamic> map, String id) {
    return TimelineEventModel(
      id: id,
      groupId: map['groupId'] ?? '',
      type: map['type'] ?? '',
      actorMemberId: map['actorMemberId'] ?? '',
      actorName: map['actorName'] ?? '',
      description: map['description'] ?? '',
      targetType: map['targetType'],
      targetId: map['targetId'],
      snapshot: map['snapshot'] as Map<String, dynamic>?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
