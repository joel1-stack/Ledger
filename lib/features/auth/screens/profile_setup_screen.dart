import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_illustrations.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/theme/app_strings.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../router/app_router.dart';
import '../../../shared/widgets/app_text_field.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  final String phone;
  const ProfileSetupScreen({required this.phone, super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    final name = _nameController.text.trim();
    if (name.length < 2) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).registerWithPhone(widget.phone, name);
      if (mounted) context.go(RouteNames.groupList);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text(''), backgroundColor: Colors.transparent),
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
                  AppIllustrations.profile,
                  fit: BoxFit.contain,
                  placeholderBuilder: (_) => Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      gradient: AppColors.secondaryGradient,
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: const Icon(Icons.person_add_rounded, size: 56, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                label: const Text('Add Photo (Optional)', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 40),
              Text(AppStrings.completeProfile, style: AppTypography.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: 32),
              AppTextField(
                controller: _nameController,
                label: AppStrings.fullName,
                hint: 'e.g. Joel Kaunda',
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _nameController.text.trim().length >= 2
                        ? [BoxShadow(color: AppColors.primary, blurRadius: 12, offset: const Offset(0, 6))]
                        : null,
                  ),
                  child: ElevatedButton(
                    onPressed: _nameController.text.trim().length >= 2 && !_isLoading ? _complete : null,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, disabledBackgroundColor: AppColors.divider),
                    child: _isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text(AppStrings.complete, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
