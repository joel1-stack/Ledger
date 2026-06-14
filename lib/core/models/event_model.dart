import 'package:cloud_firestore/cloud_firestore.dart';
import '../enums/event_type.dart';

class EventModel {
  final String id;
  final String groupId;
  final EventType type;
  final String title;
  final String? description;
  final double targetAmount;
  final double collectedAmount;
  final double requiredPerMember;
  final DateTime deadline;
  final String status;
  final String createdBy;
  final DateTime createdAt;

  EventModel({
    required this.id,
    required this.groupId,
    required this.type,
    required this.title,
    this.description,
    this.targetAmount = 0,
    this.collectedAmount = 0,
    this.requiredPerMember = 0,
    required this.deadline,
    this.status = 'active',
    required this.createdBy,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'type': type.name,
      'title': title,
      'description': description,
      'targetAmount': targetAmount,
      'collectedAmount': collectedAmount,
      'requiredPerMember': requiredPerMember,
      'deadline': Timestamp.fromDate(deadline),
      'status': status,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map, String id) {
    return EventModel(
      id: id,
      groupId: map['groupId'] ?? '',
      type: EventType.fromString(map['type'] ?? 'other'),
      title: map['title'] ?? '',
      description: map['description'],
      targetAmount: (map['targetAmount'] ?? 0).toDouble(),
      collectedAmount: (map['collectedAmount'] ?? 0).toDouble(),
      requiredPerMember: (map['requiredPerMember'] ?? 0).toDouble(),
      deadline: (map['deadline'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'active',
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
