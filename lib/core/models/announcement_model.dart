import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String id;
  final String groupId;
  final String title;
  final String message;
  final String sentBy;
  final String sentByName;
  final DateTime sentAt;
  final List<String> readBy;

  AnnouncementModel({
    required this.id,
    required this.groupId,
    required this.title,
    required this.message,
    required this.sentBy,
    required this.sentByName,
    required this.sentAt,
    this.readBy = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'title': title,
      'message': message,
      'sentBy': sentBy,
      'sentByName': sentByName,
      'sentAt': Timestamp.fromDate(sentAt),
      'readBy': readBy,
    };
  }

  factory AnnouncementModel.fromMap(Map<String, dynamic> map, String id) {
    return AnnouncementModel(
      id: id,
      groupId: map['groupId'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      sentBy: map['sentBy'] ?? '',
      sentByName: map['sentByName'] ?? '',
      sentAt: (map['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readBy: List<String>.from(map['readBy'] ?? []),
    );
  }
}
