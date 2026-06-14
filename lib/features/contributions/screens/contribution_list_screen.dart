import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/contributions_provider.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/app_empty_state.dart';
import 'record_payment_screen.dart';

class ContributionListScreen extends ConsumerWidget {
  final String groupId;
  const ContributionListScreen({required this.groupId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contributions = ref.watch(contributionsProvider(groupId));
    final types = ref.watch(contributionTypesProvider(groupId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Contributions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => RecordPaymentScreen(groupId: groupId),
            )),
          ),
        ],
      ),
      body: contributions.when(
        data: (data) {
          final totalCollected = data.where((r) => r.status.name == 'paid').fold<double>(0, (s, r) => s + r.amount);
          final pendingCount = data.where((r) => r.status.name == 'pending').length;

          return Column(
            children: [
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(child: _statBox('Collected', CurrencyFormat.formatShort(totalCollected), AppColors.success, Icons.check_circle)),
                      Container(width: 1, height: 40, color: AppColors.divider),
                      Expanded(child: _statBox('Pending', '$pendingCount', AppColors.warning, Icons.pending)),
                      Container(width: 1, height: 40, color: AppColors.divider),
                      Expanded(child: _statBox('Total', '${data.length}', AppColors.primary, Icons.receipt_long)),
                    ],
                  ),
                ),
              ),

              // By Type Summary
              types.when(
                data: (typeList) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: typeList.map((t) {
                      final paid = data.where((r) => r.typeId == t.id && r.status.name == 'paid').length;
                      final total = data.where((r) => r.typeId == t.id).length;
                      return Card(
                        child: ListTile(
                          title: Text(t.name),
                          subtitle: LinearProgressIndicator(
                            value: total > 0 ? paid / total : 0,
                            backgroundColor: AppColors.divider,
                            color: AppColors.primary,
                          ),
                          trailing: Text('$paid/$total paid'),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                loading: () => const SizedBox(),
                error: (_, _) => const SizedBox(),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recent Records', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    Text('${data.length} total', style: TextStyle(color: AppColors.textTertiary)),
                  ],
                ),
              ),

              Expanded(
                child: data.isEmpty
                    ? const AppEmptyState(title: 'No Contributions', subtitle: 'Record your first payment')
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: data.length,
                        itemBuilder: (_, i) {
                          final rec = data[i];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: (rec.status.name == 'paid' ? AppColors.success : AppColors.warning).withValues(alpha: 0.1),
                                child: Icon(rec.status.name == 'paid' ? Icons.check : Icons.schedule, color: rec.status.name == 'paid' ? AppColors.success : AppColors.warning, size: 20),
                              ),
                              title: Text(rec.memberName, style: const TextStyle(fontWeight: FontWeight.w500)),
                              subtitle: Text('${rec.typeName} | ${DateHelpers.formatDate(rec.paidAt)}'),
                              trailing: Text(CurrencyFormat.format(rec.amount), style: TextStyle(fontWeight: FontWeight.bold, color: rec.status.name == 'paid' ? AppColors.success : AppColors.warning)),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const AppLoading(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _statBox(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
      ],
    );
  }
}
