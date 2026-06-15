import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_illustrations.dart';
import '../../../core/models/group_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/group_provider.dart';
import '../../../core/services/firestore_service.dart';
import '../../../shared/theme/app_strings.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../router/app_router.dart';

class GroupListScreen extends ConsumerWidget {
  const GroupListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseUser = ref.watch(currentUserProvider);
    final groupsAsync = firebaseUser != null
        ? ref.watch(userGroupsProvider2(firebaseUser.uid))
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) context.go(RouteNames.landing);
            },
          ),
        ],
      ),
      body: groupsAsync == null || groupsAsync is AsyncLoading
          ? _buildEmptyState()
          : groupsAsync.when(
              data: (groups) => groups.isEmpty
                  ? _buildEmptyState()
                  : _buildGroupsList(context, ref, groups),
              loading: () => const AppLoading(),
              error: (_, _) => _buildEmptyState(),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go(RouteNames.groupModel),
                    icon: const Icon(Icons.add),
                    label: const Text(AppStrings.createGroup),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => _showJoinDialog(context, ref),
                    icon: const Icon(Icons.login),
                    label: const Text(AppStrings.joinGroup),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupsList(BuildContext context, WidgetRef ref, List<GroupModel> groups) {
    if (groups.isEmpty) return _buildEmptyState();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groups.length,
      itemBuilder: (_, i) {
        final group = groups[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(group.name[0].toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
            title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${group.stats.totalMembers} members'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ref.read(currentGroupIdProvider.notifier).state = group.id;
              context.go(RouteNames.home);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                AppIllustrations.people,
                width: 200, height: 200, fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 32),
            const Text(AppStrings.noGroups, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(AppStrings.noGroupsSub,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  void _showJoinDialog(BuildContext context, WidgetRef ref) {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.joinGroup),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(hintText: 'Enter invite code'),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            Text('Ask the group chairman to add you. Share your phone number with them.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final code = codeCtrl.text.trim();
              if (code.isEmpty) return;
              Navigator.pop(ctx);
              final service = ref.read(firestoreServiceProvider);
              final group = await service.getGroupByInviteCode(code);
              if (!context.mounted) return;
              if (group == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid invite code')),
                );
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Group "${group.name}" found. Ask the chairman to add you.')),
              );
            },
            child: const Text('Look Up'),
          ),
        ],
      ),
    );
  }
}
