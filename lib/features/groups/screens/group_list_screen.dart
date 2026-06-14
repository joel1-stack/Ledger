import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/group_provider.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/models/user_model.dart';
import '../../../shared/theme/app_strings.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../router/app_router.dart';

class GroupListScreen extends ConsumerWidget {
  const GroupListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) context.go(RouteNames.welcome);
            },
          ),
        ],
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return const AppEmptyState(
              title: AppStrings.noGroups,
              subtitle: AppStrings.noGroupsSub,
              icon: Icons.group_outlined,
            );
          }
          final userProfile = ref.watch(userProfileProvider(user.uid));
          return userProfile.when(
            data: (profile) {
              if (profile == null || profile.groupIds.isEmpty) {
                return _buildEmptyState(context);
              }
              final groups = ref.watch(userGroupsProvider(profile.groupIds));
              return groups.when(
                data: (data) {
                  if (data.isEmpty) return _buildEmptyState(context);
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: data.length,
                    itemBuilder: (_, i) {
                      final group = data[i];
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
                },
                loading: () => const AppLoading(),
                error: (_, __) => _buildEmptyState(context),
              );
            },
            loading: () => const AppLoading(),
            error: (_, __) => _buildEmptyState(context),
          );
        },
        loading: () => const AppLoading(),
        error: (_, __) => _buildEmptyState(context),
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
                    onPressed: () => context.go(RouteNames.groupCreate),
                    icon: const Icon(Icons.add),
                    label: const Text(AppStrings.createGroup),
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

  Widget _buildEmptyState(BuildContext context) {
    return const AppEmptyState(
      title: AppStrings.noGroups,
      subtitle: AppStrings.noGroupsSub,
      icon: Icons.group_outlined,
    );
  }

  void _showJoinDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.joinGroup),
        content: TextField(
          decoration: const InputDecoration(hintText: 'Enter invite code'),
          textCapitalization: TextCapitalization.characters,
          onSubmitted: (code) async {
            Navigator.pop(ctx);
            final service = ref.read(firestoreServiceProvider);
            final group = await service.getGroupByInviteCode(code);
            if (group == null) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid invite code')));
              }
              return;
            }
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Request sent to join ${group.name}. Wait for chairman approval.')),
              );
            }
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () {}, child: const Text('Join')),
        ],
      ),
    );
  }
}
