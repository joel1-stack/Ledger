import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_illustrations.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../router/app_router.dart';

class GroupModelScreen extends ConsumerStatefulWidget {
  const GroupModelScreen({super.key});

  @override
  ConsumerState<GroupModelScreen> createState() => _GroupModelScreenState();
}

class _GroupModelScreenState extends ConsumerState<GroupModelScreen> {
  int _navIndex = 1;

  static const _modelKeys = [
    'funeral_welfare',
    'investment_chama',
    'wedding',
    'community_project',
    'sacco',
    'church',
    'custom',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Ledger', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary), onPressed: () {}),
          IconButton(icon: const Icon(Icons.person_outline, color: AppColors.textSecondary), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        children: [
          const Text('What kind of community\nare you creating?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.2)),
          const SizedBox(height: 4),
          const Text('Choose a template to get started',
              style: TextStyle(fontSize: 14, color: AppColors.textTertiary)),
          const SizedBox(height: 20),
          ..._modelKeys.asMap().entries.map((e) => _buildCard(context, e.key, e.value)),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildDrawer() {
    final user = ref.read(currentUserProvider);
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(user?.displayName ?? 'Ledger User',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text('Community Operating System',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _drawerItem(Icons.home_outlined, 'Home', () { Navigator.pop(context); context.go(RouteNames.home); }),
                  _drawerItem(Icons.people_outline, 'My Groups', () { Navigator.pop(context); context.go(RouteNames.groupList); }),
                  _drawerItem(Icons.timeline_outlined, 'Timeline', () => Navigator.pop(context)),
                  _drawerItem(Icons.bar_chart_outlined, 'Reports', () => Navigator.pop(context)),
                  _drawerItem(Icons.notifications_outlined, 'Notifications', () => Navigator.pop(context)),
                  const Divider(),
                  _drawerItem(Icons.settings_outlined, 'Settings', () => Navigator.pop(context)),
                  _drawerItem(Icons.help_outline, 'Help', () => Navigator.pop(context)),
                  _drawerItem(Icons.logout, 'Logout', () {
                    Navigator.pop(context);
                    ref.read(authServiceProvider).signOut();
                    context.go(RouteNames.landing);
                  }, color: AppColors.error),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, int index, String modelKey) {
    final visual = AppIllustrations.modelVisuals[modelKey]!;
    return Container(
      height: 140,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(RouteNames.groupCreate, extra: modelKey),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (visual.imageUrl != null)
                CachedNetworkImage(imageUrl: visual.imageUrl!, fit: BoxFit.cover, errorWidget: (_, __, ___) => const SizedBox()),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(visual.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white,
                          shadows: [Shadow(color: Colors.black45, blurRadius: 6)],
                        )),
                    const SizedBox(height: 2),
                    Text(visual.subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                        )),
                  ],
                ),
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 8)],
                  ),
                  child: const Text('Use Template', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: (index * 80).ms).slideY(begin: 0.05, curve: Curves.easeOutCubic);
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.home_outlined, 'Home', () => context.go(RouteNames.home)),
              _navItem(1, Icons.people_outline, 'Groups', null),
              const SizedBox(width: 48),
              _navItem(3, Icons.timeline_outlined, 'Timeline', null),
              _navItem(4, Icons.person_outline, 'Profile', null),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label, void Function()? onTap) {
    final isSelected = _navIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? AppColors.primary : AppColors.textTertiary, size: 24),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: isSelected ? AppColors.primary : AppColors.textTertiary)),
            ],
          ),
        ),
      ),
    );
  }
}
