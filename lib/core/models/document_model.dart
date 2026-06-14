import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentModel {
  final String id;
  final String groupId;
  final String title;
  final String fileUrl;
  final String type;
  final String uploadedBy;
  final DateTime createdAt;

  DocumentModel({
    required this.id,
    required this.groupId,
    required this.title,
    required this.fileUrl,
    this.type = 'other',
    required this.uploadedBy,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'title': title,
      'fileUrl': fileUrl,
      'type': type,
      'uploadedBy': uploadedBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory DocumentModel.fromMap(Map<String, dynamic> map, String id) {
    return DocumentModel(
      id: id,
      groupId: map['groupId'] ?? '',
      title: map['title'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      type: map['type'] ?? 'other',
      uploadedBy: map['uploadedBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
