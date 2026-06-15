import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppIllustrations {
  AppIllustrations._();

  static const String baseUrl = 'https://42f2671d685f51e10fc6-b9fcecea3e50b3b59bdc28dead054ebc.ssl.cf5.rackcdn.com/illustrations';

  // We keep a few reliable SVG URLs for screens that need them
  static const String confirmation = '$baseUrl/confirmation_2uy0.svg';
  static const String emptySvg = '$baseUrl/empty_xct9.svg';
  static const String teamSpirit = '$baseUrl/team_spirit_hrr4.svg';
  static const String mobilePayments = '$baseUrl/mobile_payments_edgf.svg';
  static const String goal = '$baseUrl/goal_0v5v.svg';

  // For model cards: return reliable gradient & icon data
  static Map<String, ModelVisual> get modelVisuals => _buildVisuals();

  static Map<String, ModelVisual> _buildVisuals() {
    return {
      'funeral_welfare': ModelVisual(
        icon: Icons.heart_broken,
        gradient: AppColors.funeralGradient,
        title: 'Funeral Welfare',
        subtitle: 'Track emergency & death benefits for your community',
      ),
      'investment_chama': ModelVisual(
        icon: Icons.account_balance,
        gradient: AppColors.chamaGradient,
        title: 'Chama / Merry-Go-Round',
        subtitle: 'Manage shares, loans, and monthly contributions',
      ),
      'wedding': ModelVisual(
        icon: Icons.favorite,
        gradient: AppColors.weddingGradient,
        title: 'Wedding Committee',
        subtitle: 'Coordinate budgets, vendors, and contributions',
      ),
      'community_project': ModelVisual(
        icon: Icons.build,
        gradient: AppColors.communityGradient,
        title: 'Community Project',
        subtitle: 'Build together with transparent tracking',
      ),
      'sacco': ModelVisual(
        icon: Icons.savings,
        gradient: AppColors.saccoGradient,
        title: 'SACCO / Savings Group',
        subtitle: 'Member shares, loans, and dividend payouts',
      ),
      'church': ModelVisual(
        icon: Icons.church,
        gradient: AppColors.churchGradient,
        title: 'Church Group',
        subtitle: 'Tithes, offerings, building funds & ministries',
      ),
      'custom': ModelVisual(
        icon: Icons.dashboard_customize,
        gradient: AppColors.customGradient,
        title: 'Custom Group',
        subtitle: 'Start from scratch with your own rules',
      ),
    };
  }
}

class ModelVisual {
  final IconData icon;
  final LinearGradient gradient;
  final String title;
  final String subtitle;

  const ModelVisual({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.subtitle,
  });
}
