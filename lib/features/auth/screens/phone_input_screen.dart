import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sms_autofill/sms_autofill.dart';
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
  final _otpController = TextEditingController();
  bool _isValid = false;
  bool _isLoading = false;

  // Waterfall mode
  String _mode = 'input'; // input | verifying | manual
  int _elapsed = 0;
  VoidCallback? _cancelWaterfall;

  @override
  void initState() {
    super.initState();
    _tryPhoneHint();
  }

  Future<void> _tryPhoneHint() async {
    try {
      final hint = await SmsAutoFill().hint;
      if (hint != null && hint.isNotEmpty && mounted) {
        final raw = hint.replaceAll(RegExp(r'\D'), '');
        if (raw.length >= 10) {
          final last9 = raw.length > 9 ? raw.substring(raw.length - 9) : raw;
          _phoneController.text = '+254$last9';
          setState(() => _isValid = last9.length == 9 && last9.startsWith('7'));
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _cancelWaterfall?.call();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _onPhoneChanged(String value) {
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    setState(() => _isValid = cleaned.length == 12 && cleaned.startsWith('254'));
  }

  void _startWaterfall() {
    if (!_isValid) return;
    setState(() {
      _mode = 'verifying';
      _elapsed = 0;
    });
    _animateElapsed();

    final handler = ref.read(phoneAuthProvider);
    handler.startWaterfall(
      phone: _phoneController.text,
      onAutoVerified: () => _onSuccess(),
      onCodeSent: () {},
      onManualOtpNeeded: (vid) {
        if (mounted) setState(() => _mode = 'manual');
      },
    ).then((cancel) => _cancelWaterfall = cancel);
  }

  void _animateElapsed() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || _mode != 'verifying') return false;
      setState(() => _elapsed++);
      return _elapsed < 15;
    });
  }

  void _onSuccess() async {
    if (!mounted) return;
    final user = ref.read(currentUserProvider);
    if (user != null) {
      final profile = await ref.read(userProfileProvider(user.uid).future);
      if (mounted) context.go(profile != null ? RouteNames.home : RouteNames.profileSetup);
    } else if (mounted) {
      context.go(RouteNames.profileSetup);
    }
  }

  Future<void> _verifyManual() async {
    final code = _otpController.text.trim();
    if (code.length < 6) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(phoneAuthProvider).verifyOTP(code);
      _onSuccess();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid code. Try again.')),
        );
      }
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
                width: 200, height: 200,
                child: SvgPicture.network(
                  _mode == 'verifying' ? AppIllustrations.security : AppIllustrations.mobileApp,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 40),
              if (_mode == 'input') _buildInputMode(),
              if (_mode == 'verifying') _buildVerifyingMode(),
              if (_mode == 'manual') _buildManualMode(),
              const Spacer(),
              if (_mode == 'input')
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

  Widget _buildInputMode() {
    return Column(
      children: [
        Text('Enter Your Phone Number', style: AppTypography.headlineMedium, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text("We'll verify your number instantly",
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
                decoration: BoxDecoration(border: Border(right: BorderSide(color: AppColors.divider))),
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
          width: double.infinity, height: 56,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: _isValid
                  ? [BoxShadow(color: AppColors.primary, blurRadius: 12, offset: const Offset(0, 6))]
                  : null,
            ),
            child: ElevatedButton(
              onPressed: _isValid ? _startWaterfall : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                disabledBackgroundColor: AppColors.divider,
              ),
              child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyingMode() {
    final progress = (_elapsed / 15).clamp(0.0, 1.0);
    return Column(
      children: [
        Text('Verifying your number...', style: AppTypography.headlineMedium, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(_phoneController.text,
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary, fontSize: 18)),
        ),
        const SizedBox(height: 32),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.scaffoldBackground,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _elapsed < 3
              ? 'Checking your SIM automatically...'
              : _elapsed < 8
                  ? 'Reading SMS automatically...'
                  : 'Taking longer than expected...',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Text('No code needed', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
      ],
    );
  }

  Widget _buildManualMode() {
    return Column(
      children: [
        Text('Enter the code sent to', style: AppTypography.headlineMedium, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(_phoneController.text.replaceAll('+254', '0'),
            style: AppTypography.headlineSmall.copyWith(color: AppColors.primary)),
        const SizedBox(height: 32),
        TextField(
          controller: _otpController,
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
          onChanged: (v) {
            setState(() {});
            if (v.length == 6) _verifyManual();
          },
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () {
            setState(() => _mode = 'input');
            _startWaterfall();
          },
          child: const Text('Resend Code',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity, height: 56,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: _otpController.text.length >= 6
                  ? [BoxShadow(color: AppColors.primary, blurRadius: 12, offset: const Offset(0, 6))]
                  : null,
            ),
            child: ElevatedButton(
              onPressed: _otpController.text.length >= 6 && !_isLoading ? _verifyManual : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                disabledBackgroundColor: AppColors.divider,
              ),
              child: _isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('Verify', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ],
    );
  }
}
