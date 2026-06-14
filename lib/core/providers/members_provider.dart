import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../models/member_model.dart';

final membersProvider = StreamProvider.family<List<MemberModel>, String>((ref, groupId) {
  return ref.watch(firestoreServiceProvider).streamMembers(groupId);
});

final memberProvider = StreamProvider.family<MemberModel?, ({String groupId, String memberId})>((ref, params) {
  return ref.watch(firestoreServiceProvider).streamMember(params.groupId, params.memberId);
});
