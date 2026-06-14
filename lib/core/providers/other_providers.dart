import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../models/document_model.dart';
import '../models/announcement_model.dart';

final documentsProvider = StreamProvider.family<List<DocumentModel>, String>((ref, groupId) {
  return ref.watch(firestoreServiceProvider).streamDocuments(groupId);
});

final announcementsProvider = StreamProvider.family<List<AnnouncementModel>, String>((ref, groupId) {
  return ref.watch(firestoreServiceProvider).streamAnnouncements(groupId);
});
