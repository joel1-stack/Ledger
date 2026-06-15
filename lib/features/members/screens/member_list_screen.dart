import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/enums/member_role.dart';
import '../../../core/providers/members_provider.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/app_empty_state.dart';
import 'member_detail_screen.dart';

class MemberListScreen extends ConsumerWidget {
  final String groupId;
  const MemberListScreen({required this.groupId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(membersProvider(groupId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Members'),
        actions: [
          IconButton(icon: const Icon(Icons.person_add), onPressed: () {}),
        ],
      ),
      body: members.when(
        data: (data) {
          if (data.isEmpty) {
            return const AppEmptyState(title: 'No Members Yet', subtitle: 'Add members to get started');
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search members...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: data.length,
                  itemBuilder: (_, i) {
                    final member = data[i];
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
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryLight,
                          child: Text(member.name[0].toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                        title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Member #${member.memberNumber}',
                            style: const TextStyle(color: AppColors.textTertiary)),
                        trailing: _buildRoleBadge(member.role),
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => MemberDetailScreen(groupId: groupId, memberId: member.id),
                        )),
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

  Widget _buildRoleBadge(MemberRole role) {
    Color color = AppColors.textSecondary;
    String label = '';
    switch (role) {
      case MemberRole.chairman:
        color = AppColors.primary;
        label = 'Chairman';
        break;
      case MemberRole.treasurer:
        color = AppColors.accent;
        label = 'Treasurer';
        break;
      case MemberRole.secretary:
        color = AppColors.secondary;
        label = 'Secretary';
        break;
      case MemberRole.member:
        return const SizedBox();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
