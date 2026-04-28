part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [
        email,
        password,
      ];
}

class AuthRegisterRequested extends AuthEvent {
  final String lastName;
  final String firstName;
  final String? patronymic;
  final String email;
  final String password;
  final String confirmPassword;

  const AuthRegisterRequested({
    required this.lastName,
    required this.firstName,
    required this.patronymic,
    required this.email,
    required this.password,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [
        lastName,
        firstName,
        patronymic,
        email,
        password,
        confirmPassword,
      ];
}

class AuthProfileUpdateRequested extends AuthEvent {
  final String lastName;
  final String firstName;
  final String? patronymic;

  const AuthProfileUpdateRequested({
    required this.lastName,
    required this.firstName,
    required this.patronymic,
  });

  @override
  List<Object?> get props => [
        lastName,
        firstName,
        patronymic,
      ];
}

class AuthPasswordChangeRequested extends AuthEvent {
  final String oldPassword;
  final String newPassword;
  final String confirmPassword;

  const AuthPasswordChangeRequested({
    required this.oldPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [
        oldPassword,
        newPassword,
        confirmPassword,
      ];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthSessionExpired extends AuthEvent {
  final String message;

  const AuthSessionExpired({
    required this.message,
  });

  @override
  List<Object?> get props => [
        message,
      ];
}