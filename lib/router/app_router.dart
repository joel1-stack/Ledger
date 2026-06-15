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
    GoRoute(path: RouteNames.splash, builder: (_, _) => const SplashScreen()),
    GoRoute(path: RouteNames.welcome, builder: (_, _) => const WelcomeScreen()),
    GoRoute(path: RouteNames.howItWorks, builder: (_, _) => const HowItWorksScreen()),
    GoRoute(path: RouteNames.phoneInput, builder: (_, _) => const PhoneInputScreen()),
    GoRoute(
      path: RouteNames.otpVerify,
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>;
        return OtpVerifyScreen(
          verificationId: extra['vid'] as String,
          phone: extra['phone'] as String,
        );
      },
    ),
    GoRoute(
      path: RouteNames.profileSetup,
      builder: (_, state) => const ProfileSetupScreen(),
    ),
    GoRoute(path: RouteNames.groupList, builder: (_, _) => const GroupListScreen()),
    GoRoute(path: RouteNames.groupCreate, builder: (_, _) => const GroupCreateScreen()),
    GoRoute(path: RouteNames.inviteMembers, builder: (_, state) => InviteMembersScreen(groupId: state.extra as String)),
    GoRoute(path: RouteNames.home, builder: (_, _) => const HomeScreen()),
  ],
);
