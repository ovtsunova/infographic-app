import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/presentation/pages/admin_page.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/educational_data/presentation/pages/educational_data_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/infographic_builder/presentation/pages/infographic_builder_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/saved_infographics/presentation/pages/saved_infographics_page.dart';
import '../shared/models/app_user.dart';
import '../shared/widgets/app_shell.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

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

GoRouter createAppRouter(AuthBloc authBloc) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppPaths.home,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      return _authRedirect(
        state: state,
        authState: authBloc.state,
      );
    },
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
}

String? _authRedirect({
  required GoRouterState state,
  required AuthState authState,
}) {
  final path = state.uri.path;

  final isCheckingAuth =
      authState.status == AuthStatus.initial ||
      authState.status == AuthStatus.loading;

  if (isCheckingAuth) {
    return null;
  }

  final isAuthPage = path == AppPaths.login || path == AppPaths.register;

  final isPublicPage = path == AppPaths.home || isAuthPage;

  final isUserPage = path == AppPaths.dashboard ||
      path == AppPaths.educationalData ||
      path == AppPaths.infographicBuilder ||
      path == AppPaths.savedInfographics ||
      path == AppPaths.profile;

  final isAdminPage = path == AppPaths.admin;

  final isAuthenticated = authState.status == AuthStatus.authenticated;

  if (!isAuthenticated) {
    if (isPublicPage) {
      return null;
    }

    return AppPaths.login;
  }

  if (isAuthenticated && isAuthPage) {
    return AppPaths.dashboard;
  }

  if (isUserPage) {
    return null;
  }

  if (isAdminPage && authState.role.isAdmin) {
    return null;
  }

  if (isAdminPage && !authState.role.isAdmin) {
    return AppPaths.dashboard;
  }

  return null;
}

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();

    _subscription = stream.asBroadcastStream().listen(
      (_) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}