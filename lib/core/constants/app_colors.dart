import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF16A34A);
  static const Color primaryDark = Color(0xFF15803D);
  static const Color primaryLight = Color(0xFFDCFCE7);
  static const Color primaryGradientStart = Color(0xFF16A34A);
  static const Color primaryGradientEnd = Color(0xFF15803D);

  static const Color accent = Color(0xFFF59E0B);
  static const Color accentLight = Color(0xFFFEF3C7);

  static const Color secondary = Color(0xFF1E40AF);
  static const Color secondaryLight = Color(0xFFDBEAFE);

  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0891B2);
  static const Color infoLight = Color(0xFFCFFAFE);

  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color scaffoldBackground = Color(0xFFF1F5F9);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);

  static const Color divider = Color(0xFFE2E8F0);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF16A34A), Color(0xFF15803D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF1E40AF), Color(0xFF3730A3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Model card gradients — keep colorful
  static const LinearGradient funeralGradient = LinearGradient(
    colors: [Color(0xFF16A34A), Color(0xFF15803D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient chamaGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
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
