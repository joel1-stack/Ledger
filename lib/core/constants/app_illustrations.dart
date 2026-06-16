import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppIllustrations {
  AppIllustrations._();

  static const String baseUrl = 'https://42f2671d685f51e10fc6-b9fcecea3e50b3b59bdc28dead054ebc.ssl.cf5.rackcdn.com/illustrations';

  static const String confirmation = '$baseUrl/confirmation_2uy0.svg';
  static const String emptySvg = '$baseUrl/empty_xct9.svg';
  static const String teamSpirit = '$baseUrl/team_spirit_hrr4.svg';
  static const String mobilePayments = '$baseUrl/mobile_payments_edgf.svg';
  static const String goal = '$baseUrl/goal_0v5v.svg';

  static const String imgBase = 'https://picsum.photos/seed';
  static const String _imgBase = imgBase;

  static Map<String, ModelVisual> get modelVisuals => _buildVisuals();

  static Map<String, ModelVisual> _buildVisuals() {
    return {
      'funeral_welfare': ModelVisual(
        icon: Icons.heart_broken,
        gradient: AppColors.funeralGradient,
        title: 'Funeral Welfare',
        subtitle: 'Members \u2022 Contributions \u2022 Benefits',
        imageUrl: '$_imgBase/funeral/800/300',
      ),
      'investment_chama': ModelVisual(
        icon: Icons.account_balance,
        gradient: AppColors.chamaGradient,
        title: 'Chama / Merry-Go-Round',
        subtitle: 'Shares \u2022 Loans \u2022 Dividends',
        imageUrl: '$_imgBase/chama/800/300',
      ),
      'wedding': ModelVisual(
        icon: Icons.favorite,
        gradient: AppColors.weddingGradient,
        title: 'Wedding Committee',
        subtitle: 'Budget \u2022 Vendors \u2022 Contributions',
        imageUrl: '$_imgBase/wedding/800/300',
      ),
      'community_project': ModelVisual(
        icon: Icons.build,
        gradient: AppColors.communityGradient,
        title: 'Community Project',
        subtitle: 'Funds \u2022 Tasks \u2022 Progress',
        imageUrl: '$_imgBase/community/800/300',
      ),
      'sacco': ModelVisual(
        icon: Icons.savings,
        gradient: AppColors.saccoGradient,
        title: 'SACCO / Savings Group',
        subtitle: 'Shares \u2022 Loans \u2022 Dividends',
        imageUrl: '$_imgBase/sacco/800/300',
      ),
      'church': ModelVisual(
        icon: Icons.church,
        gradient: AppColors.churchGradient,
        title: 'Church Group',
        subtitle: 'Tithes \u2022 Offerings \u2022 Projects',
        imageUrl: '$_imgBase/church/800/300',
      ),
      'custom': ModelVisual(
        icon: Icons.dashboard_customize,
        gradient: AppColors.customGradient,
        title: 'Custom Group',
        subtitle: 'Your rules \u2022 Your way',
        imageUrl: '$_imgBase/custom/800/300',
      ),
    };
  }
}

class ModelVisual {
  final IconData icon;
  final LinearGradient gradient;
  final String title;
  final String subtitle;
  final String? imageUrl;

  const ModelVisual({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.subtitle,
    this.imageUrl,
  });

  static String imageUrlForModel(String modelId) {
    return AppIllustrations.modelVisuals[modelId]?.imageUrl ?? '${AppIllustrations._imgBase}/default/800/300';
  }
}
