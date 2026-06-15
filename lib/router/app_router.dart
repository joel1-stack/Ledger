import 'package:go_router/go_router.dart';
import '../features/splash/screens/splash_screen.dart';
import '../features/landing/screens/landing_screen.dart';
import '../features/groups/screens/group_list_screen.dart';
import '../features/groups/screens/group_model_screen.dart';
import '../features/groups/screens/group_create_screen.dart';
import '../features/groups/screens/group_join_screen.dart';
import '../features/groups/screens/invite_members_screen.dart';
import '../features/dashboard/screens/home_screen.dart';

class RouteNames {
  static const splash = '/';
  static const landing = '/landing';
  static const groupList = '/groups';
  static const groupModel = '/groups/model';
  static const groupCreate = '/groups/create';
  static const groupJoin = '/groups/join';
  static const inviteMembers = '/groups/invite';
  static const home = '/home';
}

final appRouter = GoRouter(
  initialLocation: RouteNames.splash,
  routes: [
    GoRoute(path: RouteNames.splash, builder: (_, _) => const SplashScreen()),
    GoRoute(path: RouteNames.landing, builder: (_, _) => const LandingScreen()),
    GoRoute(path: RouteNames.groupList, builder: (_, _) => const GroupListScreen()),
    GoRoute(path: RouteNames.groupModel, builder: (_, _) => const GroupModelScreen()),
    GoRoute(
      path: RouteNames.groupCreate,
      builder: (_, state) => GroupCreateScreen(modelId: state.extra as String?),
    ),
    GoRoute(path: RouteNames.groupJoin, builder: (_, _) => const GroupJoinScreen()),
    GoRoute(path: RouteNames.inviteMembers, builder: (_, state) => InviteMembersScreen(groupId: state.extra as String)),
    GoRoute(path: RouteNames.home, builder: (_, _) => const HomeScreen()),
  ],
);
