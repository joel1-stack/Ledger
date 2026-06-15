import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_illustrations.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../router/app_router.dart';

class HowItWorksScreen extends StatefulWidget {
  const HowItWorksScreen({super.key});

  @override
  State<HowItWorksScreen> createState() => _HowItWorksScreenState();
}

class _HowItWorksScreenState extends State<HowItWorksScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final _pages = [
    _OnboardingPage(
      illustration: AppIllustrations.teamWork,
      title: 'Create Your Group',
      description: 'Set your rules, contribution types, and invite members in minutes.',
    ),
    _OnboardingPage(
      illustration: AppIllustrations.wallet,
      title: 'Record Contributions',
      description: 'Track who paid, when, and how much. No more lost notebooks.',
    ),
    _OnboardingPage(
      illustration: AppIllustrations.timeline,
      title: 'Never Lose Memory',
      description: 'Every payment, approval, and decision is recorded forever.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return false;
      if (_currentPage < _pages.length - 1) {
        _controller.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      }
      return _currentPage < _pages.length - 1;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (_, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 220,
                          height: 220,
                          child: SvgPicture.network(
                            page.illustration,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(page.title, style: AppTypography.headlineMedium, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary, height: 1.6),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 28 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _currentPage == i ? AppColors.primary : AppColors.divider,
                    borderRadius: BorderRadius.circular(5),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
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
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      } else {
                        context.go(RouteNames.phoneInput);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                    child: Text(_currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final String illustration;
  final String title;
  final String description;
  _OnboardingPage({required this.illustration, required this.title, required this.description});
}
