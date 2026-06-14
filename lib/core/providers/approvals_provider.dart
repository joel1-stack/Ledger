import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../models/approval_model.dart';

final approvalsProvider = StreamProvider.family<List<ApprovalModel>, String>((ref, groupId) {
  return ref.watch(firestoreServiceProvider).streamApprovals(groupId);
});

final pendingApprovalsProvider = StreamProvider.family<List<ApprovalModel>, String>((ref, groupId) {
  return ref.watch(firestoreServiceProvider).streamPendingApprovals(groupId);
});
