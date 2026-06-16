import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_illustrations.dart';
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
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                SizedBox(
                  width: 160, height: 160,
                  child: SvgPicture.network(
                    AppIllustrations.confirmation,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Group Created!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('${g.name} is ready', style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 32),

                // Invite Code Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text('Share this code with members', style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onLongPress: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Code copied!')),
                          );
                        },
                        child: Text(g.inviteCode,
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 8, color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Share Code Button
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.share),
                    label: const Text('Share Code'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 16),

                // Bulk Import Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Bulk Add Members', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Import multiple members at once',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 16),
                      _bulkOption(context, Icons.contact_phone, 'From Contacts', 'Sync phone contacts', () {}),
                      const SizedBox(height: 8),
                      _bulkOption(context, Icons.paste, 'Paste List', 'Copy names/phones from WhatsApp', () => _showPasteDialog(context, ref)),
                      const SizedBox(height: 8),
                      _bulkOption(context, Icons.upload_file, 'Upload CSV', 'Bulk import from file', () {}),
                      const SizedBox(height: 8),
                      _bulkOption(context, Icons.qr_code_scanner, 'QR Code', 'Members scan to join', () {}),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => context.push(RouteNames.home),
                  child: const Text('Skip, I\'ll invite later'),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Error loading group')),
      ),
    );
  }

  Widget _bulkOption(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }

  void _showPasteDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Paste Member List'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('One per line: Name ~ Phone', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
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
            onPressed: () async {
              Navigator.pop(ctx);
              final lines = ctrl.text.trim().split('\n').where((l) => l.trim().isNotEmpty).toList();
              if (lines.isEmpty) return;
              final count = lines.length;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$count members added successfully!')),
              );
            },
            child: const Text('Add All'),
          ),
        ],
      ),
    );
  }
}
