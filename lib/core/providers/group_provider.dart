import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../models/group_model.dart';

final currentGroupIdProvider = StateProvider<String?>((ref) => null);

final currentGroupProvider = StreamProvider.family<GroupModel?, String>((ref, groupId) {
  return ref.watch(firestoreServiceProvider).streamGroup(groupId);
});

final userGroupsProvider = FutureProvider.family<List<GroupModel>, List<String>>((ref, groupIds) async {
  final groups = await ref.watch(firestoreServiceProvider).streamUserGroups(groupIds).first;
  return groups;
});
