import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_illustrations.dart';
import '../../../router/app_router.dart';

class GroupModel {
  final String id;
  final String name;
  final String description;
  final String illustration;
  final List<String> features;
  final List<String> contributionTypes;
  final Color color;

  const GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.illustration,
    required this.features,
    required this.contributionTypes,
    required this.color,
  });
}

class GroupModelScreen extends StatelessWidget {
  const GroupModelScreen({super.key});

  static const models = [
    GroupModel(
      id: 'funeral_welfare',
      name: 'Funeral Welfare',
      description: 'Burial society with death contributions, monthly fees, and emergency support for members.',
      illustration: AppIllustrations.goal,
      features: ['Death contributions', 'Monthly welfare fees', 'Emergency funds', 'Member visitations'],
      contributionTypes: ['Monthly Fee', 'Death Contribution', 'Emergency Levy'],
      color: AppColors.primary,
    ),
    GroupModel(
      id: 'investment_chama',
      name: 'Investment Chama',
      description: 'Pool savings for investments, dividends, and project funding with transparent tracking.',
      illustration: AppIllustrations.mobileMarketing,
      features: ['Share contributions', 'Dividend tracking', 'Project funding', 'Loan disbursement'],
      contributionTypes: ['Share Purchase', 'Project Contribution', 'Loan Payment'],
      color: AppColors.secondary,
    ),
    GroupModel(
      id: 'church_group',
      name: 'Church Group',
      description: 'Manage tithes, offerings, building funds, and ministry contributions with ease.',
      illustration: AppIllustrations.teamSpirit,
      features: ['Tithe tracking', 'Offerings', 'Building fund', 'Ministry projects'],
      contributionTypes: ['Tithe', 'Offering', 'Building Fund', 'Ministry Project'],
      color: AppColors.success,
    ),
    GroupModel(
      id: 'sacco',
      name: 'SACCO',
      description: 'Savings and Credit Cooperative with member shares, loan management, and dividend payouts.',
      illustration: AppIllustrations.wallet,
      features: ['Member shares', 'Loan applications', 'Interest tracking', 'Dividend payouts'],
      contributionTypes: ['Share Contribution', 'Loan Repayment', 'Savings Deposit'],
      color: AppColors.warning,
    ),
    GroupModel(
      id: 'custom',
      name: 'Custom Group',
      description: 'Start from scratch. Define your own rules, contribution types, and member roles.',
      illustration: AppIllustrations.groupChat,
      features: ['Full customization', 'Any contribution types', 'Flexible rules', 'All features enabled'],
      contributionTypes: [],
      color: AppColors.info,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Choose a Model'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: models.length,
        itemBuilder: (_, i) => _buildModelCard(context, models[i]),
      ),
    );
  }

  Widget _buildModelCard(BuildContext context, GroupModel model) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.go(RouteNames.groupCreate, extra: model.id),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    color: model.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: SvgPicture.network(
                      model.illustration,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(model.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(model.description,
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: model.features.take(3).map((f) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: model.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(f, style: TextStyle(fontSize: 11, color: model.color, fontWeight: FontWeight.w500)),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
