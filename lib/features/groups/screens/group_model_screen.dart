import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_illustrations.dart';
import '../../../router/app_router.dart';

class GroupModelScreen extends StatelessWidget {
  const GroupModelScreen({super.key});

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
        title: const Text('Choose a Model'),
        backgroundColor: AppColors.background,
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: _buildDrawer(context),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _modelKeys.length,
        itemBuilder: (_, i) => _buildModelCard(context, i, _modelKeys[i]),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
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
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.auto_graph, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ledger',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'The record your community keeps forever',
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _drawerItem(Icons.home, 'Home', () {
                    Navigator.pop(context);
                    context.go(RouteNames.home);
                  }),
                  _drawerItem(Icons.add_circle_outline, 'Create Group', () {
                    Navigator.pop(context);
                  }),
                  _drawerItem(Icons.login, 'Join Group', () {
                    Navigator.pop(context);
                    context.go(RouteNames.groupJoin);
                  }),
                  const Divider(height: 32),
                  _drawerItem(Icons.person_outline, 'My Profile', () => Navigator.pop(context)),
                  _drawerItem(Icons.help_outline, 'Help & Support', () => Navigator.pop(context)),
                  const Divider(height: 32),
                  _drawerItem(Icons.auto_graph, 'About Ledger', () => Navigator.pop(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
      onTap: onTap,
    );
  }

  Widget _buildModelCard(BuildContext context, int index, String modelKey) {
    final visual = AppIllustrations.modelVisuals[modelKey]!;
    return Container(
      height: 130,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(RouteNames.groupCreate, extra: modelKey),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Online image background
              if (visual.imageUrl != null)
                CachedNetworkImage(
                  imageUrl: visual.imageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const SizedBox(),
                ),
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        visual.gradient.colors[0].withValues(alpha: 0.9),
                        visual.gradient.colors[1].withValues(alpha: 0.75),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(visual.icon, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            visual.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            visual.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.85),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withValues(alpha: 0.8),
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(
      duration: 400.ms,
      delay: (index * 80).ms,
    ).slideX(
      begin: 0.05,
      curve: Curves.easeOutCubic,
    );
  }
}
