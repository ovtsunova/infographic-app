import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:client/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:client/src/shared/models/app_user.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState.user;

        return ListView(
          children: [
            const Text(
              'Профиль пользователя',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Раздел предназначен для просмотра учетных данных пользователя.',
              style: TextStyle(
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Данные профиля',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _ProfileField(
                      label: 'Фамилия',
                      value: user?.lastName ?? 'Не указано',
                    ),
                    _ProfileField(
                      label: 'Имя',
                      value: user?.firstName ?? 'Не указано',
                    ),
                    _ProfileField(
                      label: 'Отчество',
                      value: user?.patronymic ?? 'Не указано',
                    ),
                    _ProfileField(
                      label: 'Email',
                      value: user?.email ?? 'Не указано',
                    ),
                    _ProfileField(
                      label: 'Роль',
                      value: user?.role.title ?? 'Гость',
                    ),
                    _ProfileField(
                      label: 'Статус учетной записи',
                      value: user?.isBlocked == true
                          ? 'Заблокирована'
                          : 'Активна',
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

class _ProfileField extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileField({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        readOnly: true,
        controller: TextEditingController(text: value),
        decoration: InputDecoration(
          labelText: label,
        ),
      ),
    );
  }
}