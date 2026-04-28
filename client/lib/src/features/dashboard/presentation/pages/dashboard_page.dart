import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:client/src/app/app_router.dart';
import 'package:client/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:client/src/shared/models/app_user.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final role = authState.role;
        final user = authState.user;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) {
            return;
          }

          if (role == AppUserRole.admin) {
            context.go(AppPaths.admin);
            return;
          }

          if (role == AppUserRole.user) {
            context.go(AppPaths.educationalData);
            return;
          }

          context.go(AppPaths.home);
        });

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF4FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.dashboard_customize_rounded,
                        color: Color(0xFF2F67F6),
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      user == null
                          ? 'Переход в приложение'
                          : 'Здравствуйте, ${user.fullName}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF172033),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Выполняется переход в подходящий раздел. Роль пользователя: ${_roleTitle(role)}.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static String _roleTitle(AppUserRole role) {
    switch (role) {
      case AppUserRole.admin:
        return 'Администратор';
      case AppUserRole.user:
        return 'Пользователь';
      case AppUserRole.guest:
        return 'Гость';
    }
  }
}