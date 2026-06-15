import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary: Deep Emerald (trust, money, growth)
  static const Color primary = Color(0xFF0D8A53);
  static const Color primaryDark = Color(0xFF076B3F);
  static const Color primaryLight = Color(0xFFD1FAE5);
  static const Color primaryGradientStart = Color(0xFF0D8A53);
  static const Color primaryGradientEnd = Color(0xFF065F3A);

  // Accent: Warm Gold (premium, community value)
  static const Color accent = Color(0xFFF5A623);
  static const Color accentLight = Color(0xFFFEF3C7);

  // Secondary palette
  static const Color secondary = Color(0xFF1E40AF);
  static const Color secondaryLight = Color(0xFFDBEAFE);

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0891B2);
  static const Color infoLight = Color(0xFFCFFAFE);

  // Surfaces
  static const Color background = Color(0xFFF7F5F0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color scaffoldBackground = Color(0xFFF1F0EC);

  // Text
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF5C5C5C);
  static const Color textTertiary = Color(0xFF8E8E8E);

  static const Color divider = Color(0xFFE8E5E0);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0D8A53), Color(0xFF065F3A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFF5A623), Color(0xFFD4820A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF1E40AF), Color(0xFF3730A3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Model card gradients
  static const LinearGradient funeralGradient = LinearGradient(
    colors: [Color(0xFF0D8A53), Color(0xFF065F3A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient chamaGradient = LinearGradient(
    colors: [Color(0xFFF5A623), Color(0xFFD4820A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient weddingGradient = LinearGradient(
    colors: [Color(0xFFE11D48), Color(0xFF7C1D6C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient communityGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF1E3A8A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient saccoGradient = LinearGradient(
    colors: [Color(0xFF0891B2), Color(0xFF0E7490)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient churchGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient customGradient = LinearGradient(
    colors: [Color(0xFF475569), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient gradientForModel(String modelId) {
    switch (modelId) {
      case 'funeral_welfare':
        return funeralGradient;
      case 'investment_chama':
        return chamaGradient;
      case 'wedding':
        return weddingGradient;
      case 'community_project':
        return communityGradient;
      case 'sacco':
        return saccoGradient;
      case 'church':
        return churchGradient;
      default:
        return customGradient;
    }
  }

  static IconData iconForModel(String modelId) {
    switch (modelId) {
      case 'funeral_welfare':
        return Icons.heart_broken;
      case 'investment_chama':
        return Icons.account_balance;
      case 'wedding':
        return Icons.favorite;
      case 'community_project':
        return Icons.build;
      case 'sacco':
        return Icons.savings;
      case 'church':
        return Icons.church;
      default:
        return Icons.dashboard_customize;
    }
  }
}
