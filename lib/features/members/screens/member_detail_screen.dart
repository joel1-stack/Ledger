import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/members_provider.dart';
import '../../../core/providers/contributions_provider.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../shared/widgets/app_loading.dart';

class MemberDetailScreen extends ConsumerWidget {
  final String groupId;
  final String memberId;
  const MemberDetailScreen({required this.groupId, required this.memberId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(memberProvider((groupId: groupId, memberId: memberId)));
    final contributionsAsync = ref.watch(memberContributionsProvider((groupId: groupId, memberId: memberId)));

    return memberAsync.when(
      data: (member) {
        if (member == null) return const Center(child: Text('Member not found'));
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: Text(member.name)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(member.name[0].toUpperCase(),
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ),
                      const SizedBox(height: 12),
                      Text(member.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Member #${member.memberNumber}', style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Text(member.phone, style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      _buildStatusBadge(member.status),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Contribution History', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 12),
                      contributionsAsync.when(
                        data: (records) {
                          if (records.isEmpty) {
                            return const Text('No contributions yet', style: TextStyle(color: AppColors.textTertiary));
                          }
                          final totalPaid = records.where((r) => r.status.name == 'paid').fold<double>(0, (s, r) => s + r.amount);
                          return Column(
                            children: [
                              Row(
                                children: [
                                  const Text('Total Paid: '),
                                  Text(CurrencyFormat.format(totalPaid), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...records.take(10).map((r) => ListTile(
                                    dense: true,
                                    title: Text(r.typeName, style: const TextStyle(fontSize: 14)),
                                    subtitle: Text(DateHelpers.formatDate(r.paidAt), style: const TextStyle(fontSize: 12)),
                                    trailing: Text(CurrencyFormat.format(r.amount), style: TextStyle(fontWeight: FontWeight.w600, color: r.status.name == 'paid' ? AppColors.success : AppColors.warning)),
                                  )),
                            ],
                          );
                        },
                        loading: () => const AppLoading(),
                        error: (e, _) => Text('Error: $e'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Scaffold(body: const AppLoading()),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isActive = status == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(color: isActive ? AppColors.success : AppColors.error, fontWeight: FontWeight.w600),
      ),
    );
  }
}
