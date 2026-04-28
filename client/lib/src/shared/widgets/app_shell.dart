import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:client/src/app/app_theme.dart';
import 'package:client/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:client/src/shared/models/app_user.dart';

import 'responsive_layout.dart';
import 'side_menu.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final currentRole = authState.role;

        return ResponsiveLayout(
          mobile: _MobileShell(
            currentPath: currentPath,
            currentRole: currentRole,
            child: child,
          ),
          desktop: _DesktopShell(
            currentPath: currentPath,
            currentRole: currentRole,
            child: child,
          ),
        );
      },
    );
  }
}

class _DesktopShell extends StatelessWidget {
  final String currentPath;
  final AppUserRole currentRole;
  final Widget child;

  const _DesktopShell({
    required this.currentPath,
    required this.currentRole,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SideMenu(
            currentPath: currentPath,
            role: currentRole,
          ),
          Expanded(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppTheme.backgroundColor,
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileShell extends StatelessWidget {
  final String currentPath;
  final AppUserRole currentRole;
  final Widget child;

  const _MobileShell({
    required this.currentPath,
    required this.currentRole,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getPageTitle(currentPath)),
      ),
      drawer: Drawer(
        child: SideMenu(
          currentPath: currentPath,
          role: currentRole,
          onNavigate: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }

  String _getPageTitle(String path) {
    switch (path) {
      case '/':
        return 'Главная';
      case '/dashboard':
        return 'Рабочая область';
      case '/educational-data':
        return 'Учебные данные';
      case '/infographic-builder':
        return 'Генерация';
      case '/saved-infographics':
        return 'Сохранённые';
      case '/profile':
        return 'Профиль';
      case '/admin':
        return 'Администрирование';
      default:
        return 'EduInfo';
    }
  }
}
