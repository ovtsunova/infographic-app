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

  static AppUserRole fromApi(String? value) {
    final text = value?.toLowerCase().trim() ?? '';

    if (text.contains('администратор') ||
        text.contains('admin') ||
        text.contains('administrator')) {
      return AppUserRole.admin;
    }

    if (text.contains('пользователь') ||
        text.contains('user') ||
        text.contains('client')) {
      return AppUserRole.user;
    }

    return AppUserRole.guest;
  }
}

class AppUser {
  final int? id;
  final String email;
  final String? lastName;
  final String? firstName;
  final String? patronymic;
  final AppUserRole role;
  final bool isBlocked;

  const AppUser({
    this.id,
    required this.email,
    this.lastName,
    this.firstName,
    this.patronymic,
    required this.role,
    this.isBlocked = false,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: _readInt(json['accountId'] ?? json['userId'] ?? json['id']),
      email: json['email']?.toString() ?? '',
      lastName: json['lastName']?.toString(),
      firstName: json['firstName']?.toString(),
      patronymic: json['patronymic']?.toString(),
      role: AppUserRoleExtension.fromApi(json['role']?.toString()),
      isBlocked: json['isBlocked'] == true,
    );
  }

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

  static int? _readInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString());
  }
}