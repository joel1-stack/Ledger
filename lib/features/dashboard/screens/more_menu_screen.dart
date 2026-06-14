import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/group_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/approvals_provider.dart';
import '../../events/screens/event_list_screen.dart';
import '../../approvals/screens/approval_list_screen.dart';
import '../../documents/screens/document_list_screen.dart';
import '../../reports/screens/report_list_screen.dart';
import '../../groups/screens/group_settings_screen.dart';

class MoreMenuScreen extends ConsumerWidget {
  final String groupId;
  const MoreMenuScreen({required this.groupId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingApprovals = ref.watch(pendingApprovalsProvider(groupId));
    final pendingCount = pendingApprovals.asData?.value.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMenuItem(context, Icons.event, 'Events', () => _push(context, EventListScreen(groupId: groupId))),
          _buildMenuItem(context, Icons.verified_user, 'Approvals', () => _push(context, ApprovalListScreen(groupId: groupId)),
              badge: pendingCount > 0 ? '$pendingCount' : null),
          _buildMenuItem(context, Icons.folder, 'Documents', () => _push(context, DocumentListScreen(groupId: groupId))),
          _buildMenuItem(context, Icons.bar_chart, 'Reports', () => _push(context, ReportListScreen(groupId: groupId))),
          _buildMenuItem(context, Icons.campaign, 'Announcements', () {}),
          _buildMenuItem(context, Icons.settings, 'Group Settings', () => _push(context, GroupSettingsScreen(groupId: groupId))),
          const Divider(height: 32),
          _buildMenuItem(context, Icons.person, 'My Profile', () {}),
          _buildMenuItem(context, Icons.help_outline, 'Help & Support', () {}),
          _buildMenuItem(context, Icons.swap_horiz, 'Switch Group', () {
            ref.read(currentGroupIdProvider.notifier).state = null;
            Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
          }),
          _buildMenuItem(context, Icons.logout, 'Log Out', () async {
            await ref.read(authServiceProvider).signOut();
            if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
          }),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap, {String? badge}) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(12)),
                child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              )
            : const Icon(Icons.chevron_right, color: AppColors.textTertiary),
        onTap: onTap,
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}
