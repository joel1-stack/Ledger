import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/events_provider.dart';
import '../../../core/models/event_model.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/app_empty_state.dart';

class EventListScreen extends ConsumerWidget {
  final String groupId;
  const EventListScreen({required this.groupId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider(groupId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Events')),
      body: events.when(
        data: (data) {
          if (data.isEmpty) {
            return const AppEmptyState(title: 'No Events', subtitle: 'Create an event when something happens', icon: Icons.event_outlined);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (_, i) {
              final event = data[i];
              final progress = event.targetAmount > 0 ? event.collectedAmount / event.targetAmount : 0.0;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(_eventIcon(event.type.name), color: AppColors.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(event.title, style: const TextStyle(fontWeight: FontWeight.w600))),
                          _statusBadge(event.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (event.requiredPerMember > 0)
                        Text('KES ${event.requiredPerMember.toStringAsFixed(0)} required per member',
                            style: const TextStyle(color: AppColors.textSecondary)),
                      if (event.targetAmount > 0) ...[
                        const SizedBox(height: 8),
                        LinearProgressIndicator(value: progress, backgroundColor: AppColors.divider, color: AppColors.primary),
                        const SizedBox(height: 4),
                        Text('${CurrencyFormat.formatShort(event.collectedAmount)} / ${CurrencyFormat.formatShort(event.targetAmount)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                      ],
                      const SizedBox(height: 8),
                      Text('Deadline: ${DateHelpers.formatDate(event.deadline)}',
                          style: TextStyle(fontSize: 12, color: event.deadline.isBefore(DateTime.now()) ? AppColors.error : AppColors.textTertiary)),
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

  Widget _statusBadge(String status) {
    final isActive = status == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColors.success.withValues(alpha: 0.1) : AppColors.divider,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(isActive ? 'Active' : 'Closed', style: TextStyle(fontSize: 11, color: isActive ? AppColors.success : AppColors.textTertiary)),
    );
  }

  IconData _eventIcon(String type) {
    switch (type) {
      case 'death': return Icons.heart_broken;
      case 'wedding': return Icons.favorite;
      case 'emergency': return Icons.warning;
      case 'project': return Icons.construction;
      case 'meeting': return Icons.groups;
      default: return Icons.event;
    }
  }
}
