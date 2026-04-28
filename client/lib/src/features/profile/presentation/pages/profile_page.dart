import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:client/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:client/src/shared/models/app_user.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _patronymicController = TextEditingController();

  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _loadedUserKey;
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _patronymicController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _syncProfileControllers(AppUser? user) {
    if (user == null) {
      return;
    }

    final userKey = '${user.id ?? ''}|${user.email}|${user.lastName ?? ''}|'
        '${user.firstName ?? ''}|${user.patronymic ?? ''}';

    if (_loadedUserKey == userKey) {
      return;
    }

    _loadedUserKey = userKey;
    _lastNameController.text = user.lastName ?? '';
    _firstNameController.text = user.firstName ?? '';
    _patronymicController.text = user.patronymic ?? '';
  }

  void _submitProfile() {
    final isValid = _profileFormKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    context.read<AuthBloc>().add(
          AuthProfileUpdateRequested(
            lastName: _lastNameController.text.trim(),
            firstName: _firstNameController.text.trim(),
            patronymic: _nullIfEmpty(_patronymicController.text),
          ),
        );
  }

  void _submitPassword() {
    final isValid = _passwordFormKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    context.read<AuthBloc>().add(
          AuthPasswordChangeRequested(
            oldPassword: _oldPasswordController.text,
            newPassword: _newPasswordController.text,
            confirmPassword: _confirmPasswordController.text,
          ),
        );
  }

  void _clearPasswordFields() {
    _oldPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, authState) {
        final message = authState.message;

        if (message == null || message.trim().isEmpty) {
          return;
        }

        if (message.toLowerCase().contains('пароль успешно')) {
          _clearPasswordFields();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: authState.status == AuthStatus.failure
                ? Colors.red
                : null,
          ),
        );
      },
      builder: (context, authState) {
        final user = authState.user;
        final isBusy = authState.status == AuthStatus.loading;

        _syncProfileControllers(user);

        return Stack(
          children: [
            ListView(
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
                  'Раздел предназначен для просмотра и редактирования учетных данных пользователя.',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                _ProfileInfoCard(
                  user: user,
                ),
                const SizedBox(height: 18),
                _EditableProfileCard(
                  formKey: _profileFormKey,
                  isBusy: isBusy,
                  lastNameController: _lastNameController,
                  firstNameController: _firstNameController,
                  patronymicController: _patronymicController,
                  onSubmit: _submitProfile,
                ),
                const SizedBox(height: 18),
                _PasswordCard(
                  formKey: _passwordFormKey,
                  isBusy: isBusy,
                  oldPasswordController: _oldPasswordController,
                  newPasswordController: _newPasswordController,
                  confirmPasswordController: _confirmPasswordController,
                  obscureOldPassword: _obscureOldPassword,
                  obscureNewPassword: _obscureNewPassword,
                  obscureConfirmPassword: _obscureConfirmPassword,
                  onToggleOldPassword: () {
                    setState(() {
                      _obscureOldPassword = !_obscureOldPassword;
                    });
                  },
                  onToggleNewPassword: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                  onToggleConfirmPassword: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                  onSubmit: _submitPassword,
                ),
              ],
            ),
            if (isBusy)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.white.withOpacity(0.45),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String? _nullIfEmpty(String value) {
    final text = value.trim();

    if (text.isEmpty) {
      return null;
    }

    return text;
  }
}

class _ProfileInfoCard extends StatelessWidget {
  final AppUser? user;

  const _ProfileInfoCard({
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Текущие данные аккаунта',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            _ReadOnlyProfileField(
              label: 'Email',
              value: user?.email ?? 'Не указано',
            ),
            _ReadOnlyProfileField(
              label: 'Роль',
              value: user?.role.title ?? 'Гость',
            ),
            _ReadOnlyProfileField(
              label: 'Статус учетной записи',
              value: user?.isBlocked == true ? 'Заблокирована' : 'Активна',
            ),
          ],
        ),
      ),
    );
  }
}

class _EditableProfileCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final bool isBusy;
  final TextEditingController lastNameController;
  final TextEditingController firstNameController;
  final TextEditingController patronymicController;
  final VoidCallback onSubmit;

  const _EditableProfileCard({
    required this.formKey,
    required this.isBusy,
    required this.lastNameController,
    required this.firstNameController,
    required this.patronymicController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Редактирование профиля',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: lastNameController,
                enabled: !isBusy,
                decoration: const InputDecoration(
                  labelText: 'Фамилия',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите фамилию';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: firstNameController,
                enabled: !isBusy,
                decoration: const InputDecoration(
                  labelText: 'Имя',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите имя';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: patronymicController,
                enabled: !isBusy,
                decoration: const InputDecoration(
                  labelText: 'Отчество',
                  hintText: 'Необязательное поле',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: isBusy ? null : onSubmit,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Сохранить профиль'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final bool isBusy;
  final TextEditingController oldPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final bool obscureOldPassword;
  final bool obscureNewPassword;
  final bool obscureConfirmPassword;
  final VoidCallback onToggleOldPassword;
  final VoidCallback onToggleNewPassword;
  final VoidCallback onToggleConfirmPassword;
  final VoidCallback onSubmit;

  const _PasswordCard({
    required this.formKey,
    required this.isBusy,
    required this.oldPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.obscureOldPassword,
    required this.obscureNewPassword,
    required this.obscureConfirmPassword,
    required this.onToggleOldPassword,
    required this.onToggleNewPassword,
    required this.onToggleConfirmPassword,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Смена пароля',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Новый пароль должен содержать не менее 8 символов.',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: oldPasswordController,
                enabled: !isBusy,
                obscureText: obscureOldPassword,
                decoration: InputDecoration(
                  labelText: 'Старый пароль',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: onToggleOldPassword,
                    icon: Icon(
                      obscureOldPassword
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите старый пароль';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: newPasswordController,
                enabled: !isBusy,
                obscureText: obscureNewPassword,
                decoration: InputDecoration(
                  labelText: 'Новый пароль',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: onToggleNewPassword,
                    icon: Icon(
                      obscureNewPassword
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите новый пароль';
                  }

                  if (value.length < 8) {
                    return 'Пароль должен содержать не менее 8 символов';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: confirmPasswordController,
                enabled: !isBusy,
                obscureText: obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Подтверждение нового пароля',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: onToggleConfirmPassword,
                    icon: Icon(
                      obscureConfirmPassword
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Повторите новый пароль';
                  }

                  if (value != newPasswordController.text) {
                    return 'Пароли не совпадают';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: isBusy ? null : onSubmit,
                  icon: const Icon(Icons.lock_reset_rounded),
                  label: const Text('Изменить пароль'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyProfileField extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyProfileField({
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
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
