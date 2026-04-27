import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:client/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:client/src/shared/models/app_user.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState.user;

        return ListView(
          children: [
            Text(
              user == null
                  ? 'Панель пользователя'
                  : 'Здравствуйте, ${user.fullName}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user == null
                  ? 'Краткая сводка по загруженным учебным данным, сохранённым инфографикам и последним действиям.'
                  : 'Вы вошли в систему как: ${user.role.title}',
              style: const TextStyle(
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 1100 ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.8,
              children: const [
                _StatCard(
                  title: 'Группы',
                  value: '0',
                  icon: Icons.groups_rounded,
                ),
                _StatCard(
                  title: 'Студенты',
                  value: '0',
                  icon: Icons.school_rounded,
                ),
                _StatCard(
                  title: 'Инфографики',
                  value: '0',
                  icon: Icons.insert_chart_rounded,
                ),
                _StatCard(
                  title: 'Экспорты',
                  value: '0',
                  icon: Icons.file_download_rounded,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Текущее состояние',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      label: 'Статус авторизации',
                      value: authState.isAuthenticated
                          ? 'Пользователь авторизован'
                          : 'Пользователь не авторизован',
                    ),
                    _InfoRow(
                      label: 'Email',
                      value: user?.email ?? 'Не указан',
                    ),
                    _InfoRow(
                      label: 'Роль',
                      value: user?.role.title ?? 'Гость',
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(
              icon,
              size: 34,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          SizedBox(
            width: 190,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}