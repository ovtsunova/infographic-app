import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:client/src/features/auth/data/auth_repository.dart';
import 'package:client/src/shared/models/app_user.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  late final StreamSubscription<String> _authFailureSubscription;

  AuthBloc({
    required AuthRepository authRepository,
  })  : _authRepository = authRepository,
        super(const AuthState.initial()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthProfileUpdateRequested>(_onProfileUpdateRequested);
    on<AuthPasswordChangeRequested>(_onPasswordChangeRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthSessionExpired>(_onSessionExpired);

    _authFailureSubscription = _authRepository.authFailureStream.listen(
      (message) {
        add(AuthSessionExpired(message: message));
      },
    );
  }

  Future<void> _onStarted(
    AuthStarted event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearMessage: true,
      ),
    );

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

    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearMessage: true,
      ),
    );

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

    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearMessage: true,
      ),
    );

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

  Future<void> _onProfileUpdateRequested(
    AuthProfileUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (event.lastName.trim().isEmpty || event.firstName.trim().isEmpty) {
      emit(
        state.copyWith(
          status: state.user == null ? AuthStatus.failure : AuthStatus.authenticated,
          message: 'Введите фамилию и имя',
        ),
      );
      return;
    }

    final previousState = state;

    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearMessage: true,
      ),
    );

    try {
      final user = await _authRepository.updateProfile(
        lastName: event.lastName,
        firstName: event.firstName,
        patronymic: event.patronymic,
      );

      emit(
        AuthState(
          status: AuthStatus.authenticated,
          user: user,
          message: 'Профиль успешно обновлен',
        ),
      );
    } catch (error) {
      emit(
        previousState.copyWith(
          status: previousState.user == null
              ? AuthStatus.failure
              : AuthStatus.authenticated,
          message: error.toString(),
        ),
      );
    }
  }

  Future<void> _onPasswordChangeRequested(
    AuthPasswordChangeRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (event.oldPassword.trim().isEmpty ||
        event.newPassword.trim().isEmpty ||
        event.confirmPassword.trim().isEmpty) {
      emit(
        state.copyWith(
          status: state.user == null ? AuthStatus.failure : AuthStatus.authenticated,
          message: 'Введите старый пароль, новый пароль и подтверждение',
        ),
      );
      return;
    }

    if (event.newPassword.length < 8) {
      emit(
        state.copyWith(
          status: state.user == null ? AuthStatus.failure : AuthStatus.authenticated,
          message: 'Новый пароль должен содержать не менее 8 символов',
        ),
      );
      return;
    }

    if (event.newPassword != event.confirmPassword) {
      emit(
        state.copyWith(
          status: state.user == null ? AuthStatus.failure : AuthStatus.authenticated,
          message: 'Новый пароль и подтверждение не совпадают',
        ),
      );
      return;
    }

    final previousState = state;

    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearMessage: true,
      ),
    );

    try {
      await _authRepository.changePassword(
        oldPassword: event.oldPassword,
        newPassword: event.newPassword,
      );

      emit(
        previousState.copyWith(
          status: previousState.user == null
              ? AuthStatus.unauthenticated
              : AuthStatus.authenticated,
          message: 'Пароль успешно изменен',
        ),
      );
    } catch (error) {
      emit(
        previousState.copyWith(
          status: previousState.user == null
              ? AuthStatus.failure
              : AuthStatus.authenticated,
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

  Future<void> _onSessionExpired(
    AuthSessionExpired event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();

    emit(
      AuthState(
        status: AuthStatus.unauthenticated,
        message: event.message,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _authFailureSubscription.cancel();

    return super.close();
  }
}