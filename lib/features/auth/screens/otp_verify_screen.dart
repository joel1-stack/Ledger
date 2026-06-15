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

class OtpVerifyScreen extends ConsumerStatefulWidget {
  final String verificationId;
  final String phone;
  const OtpVerifyScreen({required this.verificationId, required this.phone, super.key});

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  int _resendSeconds = 60;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        if (_resendSeconds > 0) _resendSeconds--;
      });
      return _resendSeconds > 0;
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length < 6) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(phoneAuthProvider).verifyOTP(code);
      final user = ref.read(authServiceProvider).currentUser;
      if (user != null) {
        final profile = await ref.read(authServiceProvider).getUserProfile(user.uid);
        if (mounted) {
          context.go(profile != null ? RouteNames.home : RouteNames.profileSetup);
        }
      } else if (mounted) {
        context.go(RouteNames.profileSetup);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid code. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final phoneDisplay = widget.phone.replaceAll('+254', '0');
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text(''), backgroundColor: Colors.transparent, elevation: 0),
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
                  AppIllustrations.security,
                  fit: BoxFit.contain,
                  placeholderBuilder: (_) => Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.info, Color(0xFF2563EB)]),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(Icons.lock_outline_rounded, size: 56, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text(AppStrings.verifyPhone, style: AppTypography.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Enter the 6-digit code sent to', style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary)),
              Text(phoneDisplay, style: AppTypography.headlineSmall.copyWith(color: AppColors.primary)),
              const SizedBox(height: 32),
              TextField(
                controller: _codeController,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 12),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.scaffoldBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                onChanged: (value) {
                  setState(() {});
                  if (value.length == 6) _verify();
                },
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: _resendSeconds == 0
                    ? () {
                        ref.read(phoneAuthProvider).startWaterfall(
                          phone: widget.phone,
                          onAutoVerified: () {},
                          onCodeSent: () {
                            setState(() => _resendSeconds = 60);
                            _startResendTimer();
                          },
                          onManualOtpNeeded: (vid) {},
                        );
                      }
                    : null,
                child: Text(
                  _resendSeconds > 0 ? 'Resend in $_resendSeconds s' : 'Resend Code',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _resendSeconds == 0 ? AppColors.primary : AppColors.textTertiary,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _codeController.text.length >= 6
                        ? [BoxShadow(color: AppColors.primary, blurRadius: 12, offset: const Offset(0, 6))]
                        : null,
                  ),
                  child: ElevatedButton(
                    onPressed: _codeController.text.length >= 6 && !_isLoading ? _verify : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      disabledBackgroundColor: AppColors.divider,
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text(AppStrings.verify, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
