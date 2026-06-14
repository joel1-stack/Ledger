import 'package:cloud_firestore/cloud_firestore.dart';

class ContributionTypeModel {
  final String id;
  final String groupId;
  final String name;
  final double amount;
  final bool isOpenAmount;
  final String frequency;
  final bool mandatory;
  final DateTime createdAt;

  ContributionTypeModel({
    required this.id,
    required this.groupId,
    required this.name,
    this.amount = 0,
    this.isOpenAmount = false,
    this.frequency = 'monthly',
    this.mandatory = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'name': name,
      'amount': amount,
      'isOpenAmount': isOpenAmount,
      'frequency': frequency,
      'mandatory': mandatory,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ContributionTypeModel.fromMap(Map<String, dynamic> map, String id) {
    return ContributionTypeModel(
      id: id,
      groupId: map['groupId'] ?? '',
      name: map['name'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      isOpenAmount: map['isOpenAmount'] ?? false,
      frequency: map['frequency'] ?? 'monthly',
      mandatory: map['mandatory'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
