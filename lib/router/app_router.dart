import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/splash/screens/splash_screen.dart';
import '../features/onboarding/screens/welcome_screen.dart';
import '../features/onboarding/screens/how_it_works_screen.dart';
import '../features/auth/screens/phone_input_screen.dart';
import '../features/auth/screens/otp_verify_screen.dart';
import '../features/auth/screens/profile_setup_screen.dart';
import '../features/groups/screens/group_list_screen.dart';
import '../features/groups/screens/group_create_screen.dart';
import '../features/groups/screens/invite_members_screen.dart';
import '../features/dashboard/screens/home_screen.dart';

class RouteNames {
  static const splash = '/';
  static const welcome = '/welcome';
  static const howItWorks = '/how-it-works';
  static const phoneInput = '/phone-input';
  static const otpVerify = '/otp-verify';
  static const profileSetup = '/profile-setup';
  static const groupList = '/groups';
  static const groupCreate = '/groups/create';
  static const joinGroup = '/groups/join';
  static const inviteMembers = '/groups/invite';
  static const home = '/home';
}

final appRouter = GoRouter(
  initialLocation: RouteNames.splash,
  routes: [
    GoRoute(path: RouteNames.splash, builder: (_, __) => const SplashScreen()),
    GoRoute(path: RouteNames.welcome, builder: (_, __) => const WelcomeScreen()),
    GoRoute(path: RouteNames.howItWorks, builder: (_, __) => const HowItWorksScreen()),
    GoRoute(path: RouteNames.phoneInput, builder: (_, __) => const PhoneInputScreen()),
    GoRoute(path: RouteNames.otpVerify, builder: (_, state) => OtpVerifyScreen(verificationId: state.extra as String)),
    GoRoute(path: RouteNames.profileSetup, builder: (_, __) => const ProfileSetupScreen()),
    GoRoute(path: RouteNames.groupList, builder: (_, __) => const GroupListScreen()),
    GoRoute(path: RouteNames.groupCreate, builder: (_, __) => const GroupCreateScreen()),
    GoRoute(path: RouteNames.inviteMembers, builder: (_, state) => InviteMembersScreen(groupId: state.extra as String)),
    GoRoute(path: RouteNames.home, builder: (_, __) => const HomeScreen()),
  ],
);
