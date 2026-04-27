import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/models/app_user.dart';
import '../../data/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({
    required AuthRepository authRepository,
  })  : _authRepository = authRepository,
        super(const AuthState.initial()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onStarted(
    AuthStarted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearMessage: true));

    final token = await _authRepository.getSavedToken();

    if (token == null || token.trim().isEmpty) {
      emit(
        const AuthState(
          status: AuthStatus.unauthenticated,
        ),
      );
      return;
    }

    try {
      final user = await _authRepository.getMe();

      emit(
        AuthState(
          status: AuthStatus.authenticated,
          user: user,
        ),
      );
    } catch (error) {
      await _authRepository.logout();

      emit(
        AuthState(
          status: AuthStatus.unauthenticated,
          message: error.toString(),
        ),
      );
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (event.email.trim().isEmpty || event.password.trim().isEmpty) {
      emit(
        const AuthState(
          status: AuthStatus.failure,
          message: 'Введите email и пароль',
        ),
      );
      return;
    }

    emit(state.copyWith(status: AuthStatus.loading, clearMessage: true));

    try {
      final user = await _authRepository.login(
        email: event.email,
        password: event.password,
      );

      emit(
        AuthState(
          status: AuthStatus.authenticated,
          user: user,
        ),
      );
    } catch (error) {
      emit(
        AuthState(
          status: AuthStatus.failure,
          message: error.toString(),
        ),
      );
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (event.lastName.trim().isEmpty ||
        event.firstName.trim().isEmpty ||
        event.email.trim().isEmpty ||
        event.password.trim().isEmpty) {
      emit(
        const AuthState(
          status: AuthStatus.failure,
          message: 'Заполните фамилию, имя, email и пароль',
        ),
      );
      return;
    }

    if (event.password.length < 8) {
      emit(
        const AuthState(
          status: AuthStatus.failure,
          message: 'Пароль должен содержать не менее 8 символов',
        ),
      );
      return;
    }

    if (event.password != event.confirmPassword) {
      emit(
        const AuthState(
          status: AuthStatus.failure,
          message: 'Пароли не совпадают',
        ),
      );
      return;
    }

    emit(state.copyWith(status: AuthStatus.loading, clearMessage: true));

    try {
      await _authRepository.register(
        lastName: event.lastName,
        firstName: event.firstName,
        patronymic: event.patronymic,
        email: event.email,
        password: event.password,
      );

      final user = await _authRepository.login(
        email: event.email,
        password: event.password,
      );

      emit(
        AuthState(
          status: AuthStatus.authenticated,
          user: user,
          message: 'Регистрация выполнена успешно',
        ),
      );
    } catch (error) {
      emit(
        AuthState(
          status: AuthStatus.failure,
          message: error.toString(),
        ),
      );
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();

    emit(
      const AuthState(
        status: AuthStatus.unauthenticated,
      ),
    );
  }
}