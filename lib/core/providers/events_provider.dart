import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../models/event_model.dart';

final eventsProvider = StreamProvider.family<List<EventModel>, String>((ref, groupId) {
  return ref.watch(firestoreServiceProvider).streamEvents(groupId);
});
