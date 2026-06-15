import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/approvals_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/enums/approval_status.dart';
import '../../../core/utils/currency_format.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/app_empty_state.dart';


class ApprovalListScreen extends ConsumerWidget {
  final String groupId;
  const ApprovalListScreen({required this.groupId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvals = ref.watch(approvalsProvider(groupId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Approvals')),
      body: approvals.when(
        data: (data) {
          if (data.isEmpty) {
            return const AppEmptyState(title: 'No Approvals', subtitle: 'All decisions are clear');
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (_, i) {
              final approval = data[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(_statusIcon(approval.status), color: _statusColor(approval.status), size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(approval.description, style: const TextStyle(fontWeight: FontWeight.w600))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(approval.status).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(approval.status.label, style: TextStyle(fontSize: 11, color: _statusColor(approval.status), fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      if (approval.amount > 0) ...[
                        const SizedBox(height: 8),
                        Text('Amount: ${CurrencyFormat.format(approval.amount)}', style: const TextStyle(color: AppColors.textSecondary)),
                      ],
                      const SizedBox(height: 4),
                      Text('${approval.approvedBy.length}/${approval.requiredCount} approvals',
                          style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                      if (approval.status == ApprovalStatus.pending)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 40,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final user = ref.read(currentUserProvider);
                                      if (user == null) return;
                                      await ref.read(firestoreServiceProvider).voteOnApproval(groupId, approval.id, user.uid, true, memberName: user.displayName ?? user.uid);
                                    },
                                    icon: const Icon(Icons.check, size: 18),
                                    label: const Text('Approve'),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SizedBox(
                                  height: 40,
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final user = ref.read(currentUserProvider);
                                      if (user == null) return;
                                      await ref.read(firestoreServiceProvider).voteOnApproval(groupId, approval.id, user.uid, false, memberName: user.displayName ?? user.uid);
                                    },
                                    icon: const Icon(Icons.close, size: 18),
                                    label: const Text('Reject'),
                                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const AppLoading(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  IconData _statusIcon(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.pending: return Icons.hourglass_empty;
      case ApprovalStatus.approved: return Icons.check_circle;
      case ApprovalStatus.rejected: return Icons.cancel;
    }
  }

  Color _statusColor(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.pending: return AppColors.warning;
      case ApprovalStatus.approved: return AppColors.success;
      case ApprovalStatus.rejected: return AppColors.error;
    }
  }
}
