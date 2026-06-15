import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/group_provider.dart';
import '../../../core/services/firestore_service.dart';

class GroupSettingsScreen extends ConsumerStatefulWidget {
  final String groupId;
  const GroupSettingsScreen({required this.groupId, super.key});

  @override
  ConsumerState<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends ConsumerState<GroupSettingsScreen> {
  final _rulesCtrl = TextEditingController();
  bool _savingRule = false;

  @override
  void dispose() {
    _rulesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(currentGroupProvider(widget.groupId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Group Settings')),
      body: group.when(
        data: (g) {
          if (g == null) return const Center(child: Text('Group not found'));
          _rulesCtrl.text = g.description ?? '';
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Group Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(g.name[0].toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ),
                      const SizedBox(height: 12),
                      Text(g.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Code: ${g.inviteCode}', style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Group Rules Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.rule, color: AppColors.primary),
                          const SizedBox(width: 8),
                          const Text('Group Rules', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _rulesCtrl,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Describe your group rules...\ne.g.\n- Monthly contribution of KES 500\n- Meetings every 1st Sunday\n- 3-day notice for withdrawals',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saveRules,
                          icon: _savingRule
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.save),
                          label: Text(_savingRule ? 'Saving...' : 'Save Rules'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Other Settings
              _buildSettingTile(Icons.edit, 'Edit Group Name', () {}),
              _buildSettingTile(Icons.receipt_long, 'Contribution Types', () {}),
              _buildSettingTile(Icons.admin_panel_settings, 'Roles & Permissions', () {}),
              _buildSettingTile(Icons.toggle_on_outlined, 'Enabled Features', () {}),
              _buildSettingTile(Icons.share, 'Share Invite Code', () {}),
              _buildSettingTile(Icons.dangerous, 'Delete Group', () {}, color: AppColors.error),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildSettingTile(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color ?? AppColors.primary),
        title: Text(title, style: TextStyle(color: color ?? AppColors.textPrimary)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
        onTap: onTap,
      ),
    );
  }

  Future<void> _saveRules() async {
    setState(() => _savingRule = true);
    try {
      await ref.read(firestoreServiceProvider).updateGroup(widget.groupId, {
        'description': _rulesCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rules saved!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving rules: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingRule = false);
    }
  }
}
