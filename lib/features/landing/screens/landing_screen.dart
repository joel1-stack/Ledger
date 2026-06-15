import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_illustrations.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../router/app_router.dart';

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  static const _models = [
    _ModelCard(
      id: 'funeral_welfare',
      image: AppIllustrations.funeral,
      icon: Icons.heart_broken,
      title: 'Funeral Welfare',
      subtitle: 'Track emergency & death benefits for your community',
    ),
    _ModelCard(
      id: 'investment_chama',
      image: AppIllustrations.chama,
      icon: Icons.account_balance,
      title: 'Chama / Merry-Go-Round',
      subtitle: 'Manage shares, loans, and monthly contributions',
    ),
    _ModelCard(
      id: 'wedding',
      image: AppIllustrations.wedding,
      icon: Icons.favorite,
      title: 'Wedding Committee',
      subtitle: 'Coordinate budgets, vendors, and contributions',
    ),
    _ModelCard(
      id: 'community_project',
      image: AppIllustrations.project,
      icon: Icons.build,
      title: 'Community Project',
      subtitle: 'Build together with transparent tracking',
    ),
    _ModelCard(
      id: 'sacco',
      image: AppIllustrations.money,
      icon: Icons.savings,
      title: 'SACCO / Savings Group',
      subtitle: 'Member shares, loans, and dividend payouts',
    ),
    _ModelCard(
      id: 'church',
      image: AppIllustrations.church,
      icon: Icons.church,
      title: 'Church Group',
      subtitle: 'Tithes, offerings, building funds & ministries',
    ),
    _ModelCard(
      id: 'custom',
      image: AppIllustrations.people,
      icon: Icons.dashboard_customize,
      title: 'Custom Group',
      subtitle: 'Start from scratch with your own rules',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(anonymousAuthProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                children: [
                  const Text('Ledger',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1)),
                  const SizedBox(height: 4),
                  Text('Coordination that outlasts you',
                      style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  const Text('What are you building?',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  ..._models.map((m) => _buildCard(context, m)),
                  const SizedBox(height: 16),
                  _buildSearchSection(context, ref),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: SizedBox(
                width: double.infinity, height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => context.go(RouteNames.groupJoin),
                  icon: const Icon(Icons.login),
                  label: const Text('Already have a code?  Join Existing Group',
                      style: TextStyle(fontSize: 15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.search, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('Looking for a specific group?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Search for existing groups by name and request to join',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton.icon(
              onPressed: () => context.go(RouteNames.groupJoin),
              icon: const Icon(Icons.search, size: 20),
              label: const Text('Search Groups'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, _ModelCard model) {
    return Container(
      height: 120,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (model.id == 'custom') {
              context.go(RouteNames.groupCreate, extra: 'custom');
            } else {
              context.go(RouteNames.groupCreate, extra: model.id);
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(model.image, fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withValues(alpha: 0.6), Colors.black.withValues(alpha: 0.15)],
                    begin: Alignment.centerLeft, end: Alignment.centerRight,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(model.icon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(model.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                          const SizedBox(height: 3),
                          Text(model.subtitle,
                              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85))),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.7)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModelCard {
  final String id;
  final String image;
  final IconData icon;
  final String title;
  final String subtitle;
  const _ModelCard({
    required this.id,
    required this.image,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
