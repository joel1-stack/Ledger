import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../models/timeline_event_model.dart';

final timelineProvider = StreamProvider.family<List<TimelineEventModel>, String>((ref, groupId) {
  return ref.watch(firestoreServiceProvider).streamTimeline(groupId);
});
