import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/timeline_provider.dart';
import '../../../core/models/timeline_event_model.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/app_empty_state.dart';

class TimelineScreen extends ConsumerWidget {
  final String groupId;
  const TimelineScreen({required this.groupId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeline = ref.watch(timelineProvider(groupId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Timeline'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: timeline.when(
        data: (data) {
          if (data.isEmpty) {
            return const AppEmptyState(
              title: 'No Activity Yet',
              subtitle: 'Every payment, approval, and decision will appear here forever.',
            );
          }

          final grouped = _groupByDate(data);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: grouped.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(_dateLabel(entry.key),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ),
                  ...entry.value.map((event) => _buildEventCard(event)),
                ],
              );
            }).toList(),
          );
        },
        loading: () => const AppLoading(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildEventCard(TimelineEventModel event) {
    IconData icon;
    Color color;
    switch (event.type) {
      case 'payment':
        icon = Icons.check_circle;
        color = AppColors.success;
        break;
      case 'event':
        icon = Icons.warning_amber_rounded;
        color = AppColors.error;
        break;
      case 'approval_request':
        icon = Icons.hourglass_empty;
        color = AppColors.warning;
        break;
      case 'approval_resolved':
        icon = Icons.verified_user;
        color = AppColors.success;
        break;
      case 'announcement':
        icon = Icons.campaign;
        color = AppColors.secondary;
        break;
      default:
        icon = Icons.info_outline;
        color = AppColors.textSecondary;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.description, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text('${event.actorName} | ${DateHelpers.formatRelative(event.createdAt)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<TimelineEventModel>> _groupByDate(List<TimelineEventModel> events) {
    final map = <String, List<TimelineEventModel>>{};
    for (final e in events) {
      final key = DateHelpers.formatDate(e.createdAt);
      map.putIfAbsent(key, () => []).add(e);
    }
    return map;
  }

  String _dateLabel(String date) {
    final today = DateHelpers.formatDate(DateTime.now());
    final yesterday = DateHelpers.formatDate(DateTime.now().subtract(const Duration(days: 1)));
    if (date == today) return 'Today';
    if (date == yesterday) return 'Yesterday';
    return date;
  }
}
