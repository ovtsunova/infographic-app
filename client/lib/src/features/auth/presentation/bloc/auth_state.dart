part of 'auth_bloc.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  failure,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final AppUser? user;
  final String? message;

  const AuthState({
    required this.status,
    this.user,
    this.message,
  });

  const AuthState.initial()
      : status = AuthStatus.initial,
        user = null,
        message = null;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AppUserRole get role {
    if (status == AuthStatus.authenticated && user != null) {
      return user!.role;
    }

    return AppUserRole.guest;
  }

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? message,
    bool clearUser = false,
    bool clearMessage = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : user ?? this.user,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, user, message];
}