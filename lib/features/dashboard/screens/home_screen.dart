import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/group_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/members_provider.dart';
import '../../../core/providers/contributions_provider.dart';
import '../../../core/providers/events_provider.dart';
import '../../../core/providers/timeline_provider.dart';
import '../../../core/providers/approvals_provider.dart';
import '../../../core/models/group_model.dart';
import '../../../core/models/member_model.dart';
import '../../../core/models/contribution_record_model.dart';
import '../../../core/models/event_model.dart';
import '../../../core/models/timeline_event_model.dart';
import '../../../core/models/approval_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../shared/widgets/summary_card.dart';
import '../../../shared/widgets/quick_action_card.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/theme/app_strings.dart';
import '../../../shared/theme/app_typography.dart';
import '../../members/screens/member_list_screen.dart';
import '../../members/screens/member_detail_screen.dart';
import '../../contributions/screens/contribution_list_screen.dart';
import '../../contributions/screens/record_payment_screen.dart';
import '../../timeline/screens/timeline_screen.dart';
import '../../events/screens/create_event_screen.dart';
import '../../events/screens/event_list_screen.dart';
import '../../approvals/screens/approval_list_screen.dart';
import '../../reports/screens/report_list_screen.dart';
import '../../reports/screens/generate_report_screen.dart';
import '../../documents/screens/document_list_screen.dart';
import '../../groups/screens/group_settings_screen.dart';
import '../../dashboard/screens/more_menu_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final groupId = ref.watch(currentGroupIdProvider);
    if (groupId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ledger')),
        body: const Center(child: Text('Select a group first')),
      );
    }

    final group = ref.watch(currentGroupProvider(groupId));
    final membersAsync = ref.watch(membersProvider(groupId));
    final contributionsAsync = ref.watch(contributionsProvider(groupId));
    final eventsAsync = ref.watch(eventsProvider(groupId));
    final timelineAsync = ref.watch(timelineProvider(groupId));
    final approvalsAsync = ref.watch(pendingApprovalsProvider(groupId));

    return group.when(
      data: (g) {
        if (g == null) return const Center(child: Text('Group not found'));
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _currentIndex == 0
              ? AppBar(
                  title: Text(g.name),
                  actions: [
                    IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.person_outline), onPressed: () {}),
                  ],
                )
              : null,
          body: _buildBody(g, membersAsync, contributionsAsync, eventsAsync, timelineAsync, approvalsAsync),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Members'),
              BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet), label: 'Contrib'),
              BottomNavigationBarItem(icon: Icon(Icons.timeline_outlined), activeIcon: Icon(Icons.timeline), label: 'Timeline'),
              BottomNavigationBarItem(icon: Icon(Icons.more_horiz), activeIcon: Icon(Icons.more_horiz), label: 'More'),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: AppLoading(message: 'Loading group...')),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildBody(
    GroupModel group,
    AsyncValue<List<MemberModel>> membersAsync,
    AsyncValue<List<ContributionRecordModel>> contributionsAsync,
    AsyncValue<List<EventModel>> eventsAsync,
    AsyncValue<List<TimelineEventModel>> timelineAsync,
    AsyncValue<List<ApprovalModel>> approvalsAsync,
  ) {
    switch (_currentIndex) {
      case 0:
        return _buildDashboard(group, membersAsync, contributionsAsync, eventsAsync, timelineAsync, approvalsAsync);
      case 1:
        return MemberListScreen(groupId: group.id);
      case 2:
        return ContributionListScreen(groupId: group.id);
      case 3:
        return TimelineScreen(groupId: group.id);
      case 4:
        return MoreMenuScreen(groupId: group.id);
      default:
        return const SizedBox();
    }
  }

  Widget _buildDashboard(
    GroupModel group,
    AsyncValue<List<MemberModel>> membersAsync,
    AsyncValue<List<ContributionRecordModel>> contributionsAsync,
    AsyncValue<List<EventModel>> eventsAsync,
    AsyncValue<List<TimelineEventModel>> timelineAsync,
    AsyncValue<List<ApprovalModel>> approvalsAsync,
  ) {
    final pendingApprovals = approvalsAsync.asData?.value ?? [];
    final recentTimeline = timelineAsync.asData?.value ?? [];
    final recentContributions = contributionsAsync.asData?.value ?? [];
    final activeEvents = eventsAsync.asData?.value?.where((e) => e.status == 'active').toList() ?? [];

    return RefreshIndicator(
      onRefresh: () => Future.delayed(const Duration(seconds: 1)),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(child: SummaryCard(
                  label: 'Members',
                  value: '${group.stats.totalMembers}',
                  icon: Icons.people,
                  color: AppColors.info,
                  backgroundColor: AppColors.infoLight,
                )),
                const SizedBox(width: 12),
                Expanded(child: SummaryCard(
                  label: 'Collected',
                  value: CurrencyFormat.formatShort(group.stats.totalCollected),
                  icon: Icons.account_balance_wallet,
                  color: AppColors.success,
                  backgroundColor: AppColors.successLight,
                )),
                const SizedBox(width: 12),
                Expanded(child: SummaryCard(
                  label: 'Pending',
                  value: CurrencyFormat.formatShort(group.stats.totalOutstanding),
                  icon: Icons.pending_actions,
                  color: AppColors.warning,
                  backgroundColor: AppColors.warningLight,
                )),
              ],
            ),
            const SizedBox(height: 24),

            // Pending Approvals Banner
            if (pendingApprovals.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () => _navigateTo(ApprovalListScreen(groupId: group.id)),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppColors.secondaryGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: AppColors.secondary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('${pendingApprovals.length} pending approval${pendingApprovals.length > 1 ? 's' : ''}',
                              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),

            // Quick Actions
            const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: QuickActionCard(
                  icon: Icons.payments_rounded,
                  label: 'Record Payment',
                  onTap: () => _navigateTo(RecordPaymentScreen(groupId: group.id)),
                )),
                const SizedBox(width: 8),
                Expanded(child: QuickActionCard(
                  icon: Icons.campaign_rounded,
                  label: 'Announcement',
                  onTap: () => _showAnnouncementDialog(context),
                  color: AppColors.secondary,
                )),
                const SizedBox(width: 8),
                Expanded(child: QuickActionCard(
                  icon: Icons.description_rounded,
                  label: 'Report',
                  onTap: () => _navigateTo(GenerateReportScreen(groupId: group.id)),
                  color: AppColors.success,
                )),
                const SizedBox(width: 8),
                Expanded(child: QuickActionCard(
                  icon: Icons.event_rounded,
                  label: 'New Event',
                  onTap: () => _navigateTo(CreateEventScreen(groupId: group.id)),
                  color: AppColors.error,
                )),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: QuickActionCard(
                  icon: Icons.person_add_rounded,
                  label: 'Add Members',
                  onTap: () => _showAddMembersDialog(context, group.id),
                  color: AppColors.info,
                )),
              ],
            ),
            const SizedBox(height: 24),

            // Active Events
            if (activeEvents.isNotEmpty) ...[
              const Text('Active Events', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              ...activeEvents.take(3).map((event) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(12)),
                        child: Icon(_eventIcon(event.type.name), color: AppColors.error, size: 22),
                      ),
                      title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${event.requiredPerMember > 0 ? 'KES ${event.requiredPerMember.toStringAsFixed(0)} required' : ''} | ${DateHelpers.timeAgo(event.deadline)}',
                          style: const TextStyle(color: AppColors.textTertiary)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(8)),
                        child: Text('${(event.collectedAmount / (event.targetAmount > 0 ? event.targetAmount : 1) * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
                      ),
                    ),
                  )),
              const SizedBox(height: 16),
            ],

            // Recent Activity
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                if (recentTimeline.length > 5)
                  TextButton(
                    onPressed: () => setState(() => _currentIndex = 3),
                    child: const Text('See All →'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (recentTimeline.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 48, color: AppColors.textTertiary),
                    const SizedBox(height: 12),
                    Text('No activity yet.', style: TextStyle(color: AppColors.textTertiary)),
                    Text('Record a payment to get started.', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                  ],
                ),
              )
            else
              ...recentTimeline.take(5).map((event) => _buildTimelineTile(event)),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineTile(TimelineEventModel event) {
    IconData icon;
    Color color;
    Color bgColor;
    switch (event.type) {
      case 'payment':
        icon = Icons.check_circle;
        color = AppColors.success;
        bgColor = AppColors.successLight;
        break;
      case 'event':
        icon = Icons.warning_amber_rounded;
        color = AppColors.error;
        bgColor = AppColors.errorLight;
        break;
      case 'approval_request':
        icon = Icons.hourglass_empty;
        color = AppColors.warning;
        bgColor = AppColors.warningLight;
        break;
      case 'approval_resolved':
        icon = Icons.verified_user;
        color = AppColors.success;
        bgColor = AppColors.successLight;
        break;
      case 'announcement':
        icon = Icons.campaign;
        color = AppColors.info;
        bgColor = AppColors.infoLight;
        break;
      default:
        icon = Icons.info_outline;
        color = AppColors.textSecondary;
        bgColor = AppColors.scaffoldBackground;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(event.description, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text('${event.actorName} | ${DateHelpers.timeAgo(event.createdAt)}',
            style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
      ),
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

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _showAnnouncementDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Announcement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title', hintText: 'Emergency Meeting')),
            const SizedBox(height: 12),
            TextField(controller: msgCtrl, decoration: const InputDecoration(labelText: 'Message'), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final groupId = ref.read(currentGroupIdProvider);
              if (groupId == null) return;
              await ref.read(firestoreServiceProvider).sendAnnouncement(groupId, {
                'title': titleCtrl.text,
                'message': msgCtrl.text,
                'sentBy': ref.read(currentUserProvider)?.uid ?? '',
                'sentByName': ref.read(currentUserProvider)?.displayName ?? '',
                'sentAt': FieldValue.serverTimestamp(),
                'readBy': [],
              });
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showAddMembersDialog(BuildContext context, String groupId) {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Members'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.contact_phone),
              title: const Text('Import from Contacts'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.paste),
              title: const Text('Paste from WhatsApp'),
              subtitle: const Text('Copy group members list'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Upload CSV'),
              onTap: () => Navigator.pop(ctx),
            ),
            const Divider(),
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(labelText: 'Manual Entry', hintText: 'Name ~ Phone'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Add')),
        ],
      ),
    );
  }
}
