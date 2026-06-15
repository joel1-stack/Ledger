import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_illustrations.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../router/app_router.dart';

class PhoneInputScreen extends ConsumerStatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  ConsumerState<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends ConsumerState<PhoneInputScreen> {
  final _phoneController = TextEditingController(text: '+254');
  bool _isLoading = false;
  bool _isValid = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onPhoneChanged(String value) {
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    setState(() => _isValid = cleaned.length == 12 && cleaned.startsWith('254'));
  }

  Future<void> _continue() async {
    if (!_isValid) return;
    setState(() => _isLoading = true);
    try {
      final vid = await ref.read(phoneAuthProvider).sendOTP(_phoneController.text);
      if (mounted) {
        context.push(RouteNames.otpVerify, extra: {'vid': vid, 'phone': _phoneController.text});
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
                  AppIllustrations.mobileApp,
                  fit: BoxFit.contain,
                  placeholderBuilder: (_) => Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(Icons.phone_android_rounded, size: 56, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text('Enter Your Phone Number', style: AppTypography.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text("We'll send you a verification code",
                  style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      decoration: BoxDecoration(
                        border: Border(right: BorderSide(color: AppColors.divider)),
                      ),
                      child: const Text('🇰🇪 +254', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        onChanged: _onPhoneChanged,
                        decoration: const InputDecoration(
                          hintText: '712 345 678',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _isValid
                        ? [BoxShadow(color: AppColors.primary, blurRadius: 12, offset: const Offset(0, 6))]
                        : null,
                  ),
                  child: ElevatedButton(
                    onPressed: _isValid && !_isLoading ? _continue : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      disabledBackgroundColor: AppColors.divider,
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const Spacer(),
              Text('By continuing, you agree to our Terms and Privacy Policy',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
