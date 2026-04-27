import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/presentation/pages/admin_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/educational_data/presentation/pages/educational_data_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/infographic_builder/presentation/pages/infographic_builder_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/saved_infographics/presentation/pages/saved_infographics_page.dart';
import '../shared/widgets/app_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

class AppPaths {
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String educationalData = '/educational-data';
  static const String infographicBuilder = '/infographic-builder';
  static const String savedInfographics = '/saved-infographics';
  static const String profile = '/profile';
  static const String admin = '/admin';
}

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppPaths.home,
  routes: [
    GoRoute(
      path: AppPaths.login,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: AppPaths.register,
      builder: (context, state) => const RegisterPage(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return AppShell(child: child);
      },
      routes: [
        GoRoute(
          path: AppPaths.home,
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: AppPaths.dashboard,
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: AppPaths.educationalData,
          builder: (context, state) => const EducationalDataPage(),
        ),
        GoRoute(
          path: AppPaths.infographicBuilder,
          builder: (context, state) => const InfographicBuilderPage(),
        ),
        GoRoute(
          path: AppPaths.savedInfographics,
          builder: (context, state) => const SavedInfographicsPage(),
        ),
        GoRoute(
          path: AppPaths.profile,
          builder: (context, state) => const ProfilePage(),
        ),
        GoRoute(
          path: AppPaths.admin,
          builder: (context, state) => const AdminPage(),
        ),
      ],
    ),
  ],
);