import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:client/src/app/app_router.dart';
import 'package:client/src/app/app_theme.dart';
import 'package:client/src/features/auth/presentation/bloc/auth_bloc.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _patronymicController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _patronymicController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _register() {
    context.read<AuthBloc>().add(
          AuthRegisterRequested(
            lastName: _lastNameController.text,
            firstName: _firstNameController.text,
            patronymic: _patronymicController.text,
            email: _emailController.text,
            password: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          context.go(getAuthenticatedStartPath(state.role));
        }

        if (state.status == AuthStatus.failure && state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message!),
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state.status == AuthStatus.loading;

        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Card(
                    child: Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.035),
                            blurRadius: 26,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              onPressed: isLoading
                                  ? null
                                  : () => context.go(AppPaths.home),
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: const Text('На главную'),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const _RegisterHeader(),
                          const SizedBox(height: 28),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _lastNameController,
                                  enabled: !isLoading,
                                  decoration: const InputDecoration(
                                    labelText: 'Фамилия',
                                    prefixIcon: Icon(Icons.badge_rounded),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: TextField(
                                  controller: _firstNameController,
                                  enabled: !isLoading,
                                  decoration: const InputDecoration(
                                    labelText: 'Имя',
                                    prefixIcon: Icon(Icons.person_rounded),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _patronymicController,
                            enabled: !isLoading,
                            decoration: const InputDecoration(
                              labelText: 'Отчество',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            enabled: !isLoading,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_rounded),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            enabled: !isLoading,
                            decoration: InputDecoration(
                              labelText: 'Пароль',
                              prefixIcon: const Icon(Icons.lock_rounded),
                              suffixIcon: IconButton(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_rounded
                                      : Icons.visibility_off_rounded,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            enabled: !isLoading,
                            decoration: InputDecoration(
                              labelText: 'Подтверждение пароля',
                              prefixIcon: const Icon(Icons.verified_user_rounded),
                              suffixIcon: IconButton(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          _obscureConfirmPassword =
                                              !_obscureConfirmPassword;
                                        });
                                      },
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_rounded
                                      : Icons.visibility_off_rounded,
                                ),
                              ),
                            ),
                            onSubmitted: (_) => _register(),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _register,
                              child: isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Зарегистрироваться'),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Уже есть аккаунт?',
                                style: TextStyle(color: AppTheme.mutedTextColor),
                              ),
                              TextButton(
                                onPressed: isLoading
                                    ? null
                                    : () => context.go(AppPaths.login),
                                child: const Text('Войти'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: AppTheme.softBlueColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.person_add_alt_1_rounded,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Регистрация',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Создайте учетную запись для работы с учебной статистикой и инфографикой.',
                style: TextStyle(
                  color: AppTheme.mutedTextColor,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
