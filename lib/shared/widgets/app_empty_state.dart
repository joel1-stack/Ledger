import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_illustrations.dart';

class AppEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? illustrationUrl;

  const AppEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.illustrationUrl,
  });

  @override
  Widget build(BuildContext context) {
    final url = illustrationUrl ?? AppIllustrations.emptyState;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: SvgPicture.network(
                url,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
