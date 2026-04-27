enum AppUserRole {
  guest,
  user,
  admin,
}

extension AppUserRoleExtension on AppUserRole {
  String get title {
    switch (this) {
      case AppUserRole.guest:
        return 'Гость';
      case AppUserRole.user:
        return 'Пользователь';
      case AppUserRole.admin:
        return 'Администратор';
    }
  }

  bool get isGuest => this == AppUserRole.guest;
  bool get isUser => this == AppUserRole.user;
  bool get isAdmin => this == AppUserRole.admin;
}

class AppUser {
  final int? id;
  final String email;
  final String? lastName;
  final String? firstName;
  final String? patronymic;
  final AppUserRole role;

  const AppUser({
    this.id,
    required this.email,
    this.lastName,
    this.firstName,
    this.patronymic,
    required this.role,
  });

  String get fullName {
    final parts = [
      lastName,
      firstName,
      patronymic,
    ].where((value) => value != null && value.trim().isNotEmpty);

    if (parts.isEmpty) {
      return email;
    }

    return parts.join(' ');
  }
}