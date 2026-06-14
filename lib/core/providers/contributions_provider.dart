import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../models/contribution_type_model.dart';
import '../models/contribution_record_model.dart';

final contributionTypesProvider = StreamProvider.family<List<ContributionTypeModel>, String>((ref, groupId) {
  return ref.watch(firestoreServiceProvider).streamContributionTypes(groupId);
});

final contributionsProvider = StreamProvider.family<List<ContributionRecordModel>, String>((ref, groupId) {
  return ref.watch(firestoreServiceProvider).streamContributions(groupId);
});

final memberContributionsProvider = StreamProvider.family<List<ContributionRecordModel>, ({
  String groupId,
  String memberId
})>((ref, params) {
  return ref.watch(firestoreServiceProvider).streamMemberContributions(params.groupId, params.memberId);
});
