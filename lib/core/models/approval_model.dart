import 'package:cloud_firestore/cloud_firestore.dart';
import '../enums/approval_status.dart';

class ApprovalModel {
  final String id;
  final String groupId;
  final String type;
  final String targetId;
  final double amount;
  final String description;
  final String requestedBy;
  final List<String> approvedBy;
  final List<String> rejectedBy;
  final int requiredCount;
  final ApprovalStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  ApprovalModel({
    required this.id,
    required this.groupId,
    required this.type,
    required this.targetId,
    this.amount = 0,
    required this.description,
    required this.requestedBy,
    this.approvedBy = const [],
    this.rejectedBy = const [],
    this.requiredCount = 2,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'type': type,
      'targetId': targetId,
      'amount': amount,
      'description': description,
      'requestedBy': requestedBy,
      'approvedBy': approvedBy,
      'rejectedBy': rejectedBy,
      'requiredCount': requiredCount,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    };
  }

  factory ApprovalModel.fromMap(Map<String, dynamic> map, String id) {
    return ApprovalModel(
      id: id,
      groupId: map['groupId'] ?? '',
      type: map['type'] ?? '',
      targetId: map['targetId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      description: map['description'] ?? '',
      requestedBy: map['requestedBy'] ?? '',
      approvedBy: List<String>.from(map['approvedBy'] ?? []),
      rejectedBy: List<String>.from(map['rejectedBy'] ?? []),
      requiredCount: map['requiredCount'] ?? 2,
      status: ApprovalStatus.fromString(map['status'] ?? 'pending'),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (map['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }
}
