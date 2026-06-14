import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/group_provider.dart';
import '../../../router/app_router.dart';

class InviteMembersScreen extends ConsumerWidget {
  final String groupId;
  const InviteMembersScreen({required this.groupId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(currentGroupProvider(groupId));
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Invite Members')),
      body: group.when(
        data: (g) {
          if (g == null) return const SizedBox();
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(50)),
                  child: const Icon(Icons.check_circle_outline, size: 48, color: AppColors.success),
                ),
                const SizedBox(height: 24),
                const Text('Group Created!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('${g.name} is ready', style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text('Share this code with members', style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      Text(g.inviteCode,
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 8, color: AppColors.primary)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.share),
                    label: const Text('Share Code'),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go(RouteNames.home),
                  child: const Text('Skip, I\'ll invite later'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error loading group')),
      ),
    );
  }
}
