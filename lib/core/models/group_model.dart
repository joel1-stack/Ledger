import 'package:cloud_firestore/cloud_firestore.dart';
import '../enums/feature_flag.dart';

class GroupModel {
  final String id;
  final String name;
  final String? description;
  final String inviteCode;
  final String createdBy;
  final DateTime createdAt;
  final List<FeatureFlag> enabledFeatures;
  final GroupStats stats;

  GroupModel({
    required this.id,
    required this.name,
    this.description,
    required this.inviteCode,
    required this.createdBy,
    required this.createdAt,
    required this.enabledFeatures,
    required this.stats,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'inviteCode': inviteCode,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'enabledFeatures': enabledFeatures.map((e) => e.key).toList(),
      'stats': stats.toMap(),
    };
  }

  factory GroupModel.fromMap(Map<String, dynamic> map, String id) {
    return GroupModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'],
      inviteCode: map['inviteCode'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      enabledFeatures: (map['enabledFeatures'] as List<dynamic>?)
              ?.map((e) => FeatureFlag.fromString(e.toString()))
              .toList() ??
          [
            FeatureFlag.contributions,
            FeatureFlag.events,
            FeatureFlag.approvals,
            FeatureFlag.reports,
            FeatureFlag.documents,
            FeatureFlag.timeline,
          ],
      stats: GroupStats.fromMap(map['stats'] ?? {}),
    );
  }
}

class GroupStats {
  final int totalMembers;
  final double totalCollected;
  final double totalOutstanding;
  final int activeEvents;

  GroupStats({
    this.totalMembers = 0,
    this.totalCollected = 0.0,
    this.totalOutstanding = 0.0,
    this.activeEvents = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalMembers': totalMembers,
      'totalCollected': totalCollected,
      'totalOutstanding': totalOutstanding,
      'activeEvents': activeEvents,
    };
  }

  factory GroupStats.fromMap(Map<String, dynamic> map) {
    return GroupStats(
      totalMembers: map['totalMembers'] ?? 0,
      totalCollected: (map['totalCollected'] ?? 0).toDouble(),
      totalOutstanding: (map['totalOutstanding'] ?? 0).toDouble(),
      activeEvents: map['activeEvents'] ?? 0,
    );
  }
}
