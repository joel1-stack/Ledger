import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_illustrations.dart';
import '../../../router/app_router.dart';
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
import '../../../shared/widgets/app_loading.dart';
import '../../members/screens/member_list_screen.dart';
import '../../contributions/screens/record_payment_screen.dart';
import '../../timeline/screens/timeline_screen.dart';
import '../../events/screens/create_event_screen.dart';
import '../../events/screens/event_list_screen.dart';
import '../../approvals/screens/approval_list_screen.dart';
import '../../reports/screens/generate_report_screen.dart';
import '../../documents/screens/document_list_screen.dart';
import '../../groups/screens/group_settings_screen.dart';

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
      return _buildNoGroupScaffold();
    }

    final group = ref.watch(currentGroupProvider(groupId));
    final membersAsync = ref.watch(membersProvider(groupId));
    final contributionsAsync = ref.watch(contributionsProvider(groupId));
    final eventsAsync = ref.watch(eventsProvider(groupId));
    final timelineAsync = ref.watch(timelineProvider(groupId));
    final approvalsAsync = ref.watch(pendingApprovalsProvider(groupId));

    return group.when(
      data: (g) {
        if (g == null) return _buildNoGroupScaffold();
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(g),
          drawer: _buildDrawer(context, g, ref),
          body: _buildBody(g, membersAsync, contributionsAsync, eventsAsync, timelineAsync, approvalsAsync),
          floatingActionButton: _buildFAB(context, g.id),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: _buildBottomNav(),
        );
      },
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text('Loading group...', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: AppColors.textTertiary),
                const SizedBox(height: 16),
                Text('Something went wrong', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Text('$e', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Scaffold _buildNoGroupScaffold() {
    final user = ref.watch(currentUserProvider);
    final displayName = user?.displayName ?? '';
    final greeting = displayName.isNotEmpty ? ', $displayName' : '';
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.groups, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 32),
              Text(
                'Welcome$greeting',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select or create a group to get started',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => context.go(RouteNames.groupList),
                  icon: const Icon(Icons.group),
                  label: const Text('My Groups'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity, height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => context.go(RouteNames.groupModel),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Create New Group'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity, height: 52,
                child: TextButton.icon(
                  onPressed: () => context.go(RouteNames.groupJoin),
                  icon: const Icon(Icons.search),
                  label: const Text('Search Existing Groups'),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) context.go(RouteNames.landing);
                },
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar(GroupModel group) {
    if (_currentIndex != 0) return AppBar();
    return AppBar(
      title: Text(group.name),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {},
        ),
        Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.home_outlined, Icons.home, 'Home'),
              _navItem(1, Icons.people_outline, Icons.people, 'Members'),
              const SizedBox(width: 48),
              _navItem(3, Icons.timeline_outlined, Icons.timeline, 'Timeline'),
              Builder(
                builder: (ctx) => Expanded(
                  child: GestureDetector(
                    onTap: () => Scaffold.of(ctx).openDrawer(),
                    child: Container(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.menu, color: AppColors.textTertiary, size: 24),
                          const SizedBox(height: 2),
                          const Text('Menu', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textTertiary)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData inactive, IconData active, String label) {
    final isSelected = _currentIndex == index && ref.read(currentGroupIdProvider) != null;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (index == 4) {
            return;
          }
          final gid = ref.read(currentGroupIdProvider);
          if (gid == null && index != 0) return;
          setState(() => _currentIndex = index);
        },
        child: Container(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? active : inactive,
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildFAB(BuildContext context, String groupId) {
    return FloatingActionButton(
      onPressed: () => _showQuickActions(context, groupId),
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.add, size: 28),
    );
  }

  void _showQuickActions(BuildContext context, String groupId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _quickAction(Icons.payments_rounded, AppColors.primary, 'Record\nPayment', () { Navigator.pop(ctx); _navigateTo(RecordPaymentScreen(groupId: groupId)); })),
                  const SizedBox(width: 12),
                  Expanded(child: _quickAction(Icons.event_rounded, AppColors.accent, 'New\nEvent', () { Navigator.pop(ctx); _navigateTo(CreateEventScreen(groupId: groupId)); })),
                  const SizedBox(width: 12),
                  Expanded(child: _quickAction(Icons.campaign_rounded, AppColors.secondary, 'Send\nAnnouncement', () { Navigator.pop(ctx); _showAnnouncementDialog(context); })),
                  const SizedBox(width: 12),
                  Expanded(child: _quickAction(Icons.person_add_rounded, AppColors.info, 'Add\nMember', () { Navigator.pop(ctx); _showAddMembersDialog(context, groupId); })),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickAction(IconData icon, Color color, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, GroupModel group, WidgetRef ref) {
    final pendingApprovals = ref.watch(pendingApprovalsProvider(group.id));
    final pendingCount = pendingApprovals.asData?.value.length ?? 0;
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Text(
                      group.name[0].toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    group.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${group.stats.totalMembers} members',
                    style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _sectionHeader('QUICK ACTIONS'),
                  _drawerItem(Icons.event, 'Events', () { Navigator.pop(context); _navigateTo(EventListScreen(groupId: group.id)); }),
                  _drawerItem(Icons.verified_user, 'Approvals', () { Navigator.pop(context); _navigateTo(ApprovalListScreen(groupId: group.id)); },
                      badge: pendingCount > 0 ? '$pendingCount' : null),
                  _drawerItem(Icons.bar_chart, 'Reports', () { Navigator.pop(context); _navigateTo(GenerateReportScreen(groupId: group.id)); }),
                  _drawerItem(Icons.folder, 'Documents', () { Navigator.pop(context); _navigateTo(DocumentListScreen(groupId: group.id)); }),
                  _drawerItem(Icons.campaign, 'Announcements', () { Navigator.pop(context); _showAnnouncementDialog(context); }),
                  _sectionHeader('MANAGE'),
                  _drawerItem(Icons.settings, 'Group Settings', () {
                    Navigator.pop(context);
                    _navigateTo(GroupSettingsScreen(groupId: group.id));
                  }),
                  _drawerItem(Icons.link, 'Invite Members', () { Navigator.pop(context); }),
                  _sectionHeader('ME'),
                  _drawerItem(Icons.person, 'My Profile', () { Navigator.pop(context); }),
                  _drawerItem(Icons.help_outline, 'Help & Support', () { Navigator.pop(context); }),
                  const Divider(height: 32),
                  _drawerItem(Icons.swap_horiz, 'Switch Group', () {
                    Navigator.pop(context);
                    ref.read(currentGroupIdProvider.notifier).state = null;
                    context.go(RouteNames.groupList);
                  }),
                  _drawerItem(Icons.logout, 'Log Out', () async {
                    Navigator.pop(context);
                    await ref.read(authServiceProvider).signOut();
                    if (context.mounted) context.go(RouteNames.landing);
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textTertiary,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap, {String? badge}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(12)),
              child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            )
          : null,
      onTap: onTap,
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
      case 3:
        return TimelineScreen(groupId: group.id);
      case 4:
        return const SizedBox();
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
    final activeEvents = eventsAsync.asData?.value.where((e) => e.status == 'active').toList() ?? [];
    final totalMembers = group.stats.totalMembers;
    final totalCollected = group.stats.totalCollected;
    final totalOutstanding = group.stats.totalOutstanding;

    return RefreshIndicator(
      onRefresh: () => Future.delayed(const Duration(seconds: 1)),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main summary card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Collected',
                    style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormat.formatShort(totalCollected),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _summaryStat(Icons.people, '$totalMembers', 'Members'),
                      const SizedBox(width: 24),
                      _summaryStat(Icons.pending_actions, CurrencyFormat.formatShort(totalOutstanding), 'Pending'),
                      const SizedBox(width: 24),
                      _summaryStat(Icons.trending_up, '${activeEvents.length}', 'Events'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Pending approvals banner
            if (pendingApprovals.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () => _navigateTo(ApprovalListScreen(groupId: group.id)),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.verified_user, color: AppColors.accent, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${pendingApprovals.length} Pending Approval${pendingApprovals.length > 1 ? 's' : ''}',
                                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tap to review',
                                style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: AppColors.textTertiary, size: 14),
                      ],
                    ),
                  ),
                ),
              ),

            // Quick actions
            Row(
              children: [
                _quickActionCard(Icons.payments_rounded, 'Record\nPayment', AppColors.primary, () => _navigateTo(RecordPaymentScreen(groupId: group.id))),
                const SizedBox(width: 8),
                _quickActionCard(Icons.campaign_rounded, 'Announce\n-ment', AppColors.accent, () => _showAnnouncementDialog(context)),
                const SizedBox(width: 8),
                _quickActionCard(Icons.description_rounded, 'Generate\nReport', AppColors.success, () => _navigateTo(GenerateReportScreen(groupId: group.id))),
                const SizedBox(width: 8),
                _quickActionCard(Icons.event_rounded, 'New\nEvent', AppColors.error, () => _navigateTo(CreateEventScreen(groupId: group.id))),
              ],
            ),
            const SizedBox(height: 24),

            // This Month section
            if (totalCollected > 0 || totalOutstanding > 0) ...[
              const Text('This Month', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    _progressRow('Collection Rate', totalCollected, totalCollected + totalOutstanding, AppColors.primary),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Active Events
            if (activeEvents.isNotEmpty) ...[
              const Text('Active Events', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              ...activeEvents.take(3).map((event) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(_eventIcon(event.type.name), color: AppColors.error, size: 22),
                      ),
                      title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          if (event.requiredPerMember > 0)
                            Text('KES ${event.requiredPerMember.toStringAsFixed(0)} required',
                                style: const TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: event.targetAmount > 0 ? (event.collectedAmount / event.targetAmount).clamp(0, 1) : 0,
                              backgroundColor: AppColors.divider,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${CurrencyFormat.formatShort(event.collectedAmount)} / ${CurrencyFormat.formatShort(event.targetAmount)}',
                            style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                    ),
                  )),
              const SizedBox(height: 24),
            ],

            // Recent Activity
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                if (recentTimeline.length > 5)
                  TextButton(
                    onPressed: () => setState(() => _currentIndex = 3),
                    child: const Text('See All'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (recentTimeline.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 48, color: AppColors.textTertiary.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    const Text('No activity yet', style: TextStyle(color: AppColors.textTertiary)),
                    const SizedBox(height: 4),
                    Text(
                      'Record a payment to get started',
                      style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              ...recentTimeline.take(5).map((event) => _buildTimelineTile(event)),
            const SizedBox(height: 96), // space for bottom nav + FAB
          ],
        ),
      ),
    );
  }

  Widget _summaryStat(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
          ],
        ),
      ],
    );
  }

  Widget _quickActionCard(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _progressRow(String label, double collected, double total, Color color) {
    final ratio = (total > 0 ? (collected / total) : 0.0).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textSecondary, fontSize: 14)),
            Text('${(ratio * 100).toStringAsFixed(0)}%', style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 10,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${CurrencyFormat.formatShort(collected)} / ${CurrencyFormat.formatShort(total)}',
          style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
        ),
      ],
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
        color = AppColors.accent;
        bgColor = AppColors.accentLight;
        break;
      case 'approval_resolved':
        icon = Icons.verified_user;
        color = AppColors.success;
        bgColor = AppColors.successLight;
        break;
      case 'announcement':
        icon = Icons.campaign;
        color = AppColors.secondary;
        bgColor = AppColors.secondaryLight;
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(event.description, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(
          '${event.actorName} | ${DateHelpers.timeAgo(event.createdAt)}',
          style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
        ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('New Announcement', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title', hintText: 'Emergency Meeting'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: msgCtrl,
              decoration: const InputDecoration(labelText: 'Message'),
              maxLines: 3,
            ),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showAddMembersDialog(BuildContext context, String groupId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Members', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.contact_phone, color: AppColors.primary),
              ),
              title: const Text('Import from Contacts'),
              subtitle: const Text('Sync phone contacts'),
              onTap: () { Navigator.pop(ctx); _showComingSoon(); },
            ),
            ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.paste, color: AppColors.accent),
              ),
              title: const Text('Paste List'),
              subtitle: const Text('Copy names/phones from WhatsApp'),
              onTap: () { Navigator.pop(ctx); _showPasteDialog(context, groupId); },
            ),
            ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.upload_file, color: AppColors.info),
              ),
              title: const Text('Upload CSV'),
              subtitle: const Text('Bulk import from file'),
              onTap: () { Navigator.pop(ctx); _showComingSoon(); },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ],
      ),
    );
  }

  void _showPasteDialog(BuildContext context, String groupId) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Paste Member List'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Paste names and phone numbers (one per line, format: Name ~ Phone)'),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Joel ~ 0712345678\nAlice ~ 0723456789\nBob ~ 0734567890',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final lines = ctrl.text.trim().split('\n').where((l) => l.trim().isNotEmpty).toList();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${lines.length} members imported!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Add Members'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon!'), behavior: SnackBarBehavior.floating),
    );
  }
}
