import 'package:cloud_firestore/cloud_firestore.dart';
import '../enums/payment_status.dart';
import '../enums/payment_method.dart';

class ContributionRecordModel {
  final String id;
  final String groupId;
  final String memberId;
  final String memberName;
  final String typeId;
  final String typeName;
  final double amount;
  final PaymentStatus status;
  final PaymentMethod method;
  final String? receiptUrl;
  final String? notes;
  final String recordedBy;
  final DateTime paidAt;
  final DateTime createdAt;

  ContributionRecordModel({
    required this.id,
    required this.groupId,
    required this.memberId,
    required this.memberName,
    required this.typeId,
    required this.typeName,
    required this.amount,
    required this.status,
    required this.method,
    this.receiptUrl,
    this.notes,
    required this.recordedBy,
    required this.paidAt,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'memberId': memberId,
      'memberName': memberName,
      'typeId': typeId,
      'typeName': typeName,
      'amount': amount,
      'status': status.name,
      'method': method.name,
      'receiptUrl': receiptUrl,
      'notes': notes,
      'recordedBy': recordedBy,
      'paidAt': Timestamp.fromDate(paidAt),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ContributionRecordModel.fromMap(Map<String, dynamic> map, String id) {
    return ContributionRecordModel(
      id: id,
      groupId: map['groupId'] ?? '',
      memberId: map['memberId'] ?? '',
      memberName: map['memberName'] ?? '',
      typeId: map['typeId'] ?? '',
      typeName: map['typeName'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      status: PaymentStatus.fromString(map['status'] ?? 'pending'),
      method: PaymentMethod.fromString(map['method'] ?? 'cash'),
      receiptUrl: map['receiptUrl'],
      notes: map['notes'],
      recordedBy: map['recordedBy'] ?? '',
      paidAt: (map['paidAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
