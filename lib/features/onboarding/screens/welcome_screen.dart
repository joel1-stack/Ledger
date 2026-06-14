import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_illustrations.dart';
import '../../../shared/theme/app_strings.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../router/app_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Spacer(),
              SizedBox(
                width: 200,
                height: 200,
                child: SvgPicture.network(
                  AppIllustrations.community,
                  fit: BoxFit.contain,
                  placeholderBuilder: (_) => Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(36),
                    ),
                    child: const Icon(Icons.people_alt_rounded, size: 72, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text(AppStrings.welcomeTitle, style: AppTypography.headlineLarge),
              const SizedBox(height: 16),
              Text(
                AppStrings.welcomeSubtitle,
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary, height: 1.6),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: AppColors.primary, blurRadius: 12, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => context.go(RouteNames.phoneInput),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text(AppStrings.getStarted),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
