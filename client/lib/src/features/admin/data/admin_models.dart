class AdminDashboardStats {
  final int usersCount;
  final int groupsCount;
  final int studentsCount;
  final int disciplinesCount;
  final int infographicsCount;
  final int blockedUsersCount;

  const AdminDashboardStats({
    required this.usersCount,
    required this.groupsCount,
    required this.studentsCount,
    required this.disciplinesCount,
    required this.infographicsCount,
    required this.blockedUsersCount,
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    return AdminDashboardStats(
      usersCount: _readInt(json['usersCount']),
      groupsCount: _readInt(json['groupsCount']),
      studentsCount: _readInt(json['studentsCount']),
      disciplinesCount: _readInt(json['disciplinesCount']),
      infographicsCount: _readInt(json['infographicsCount']),
      blockedUsersCount: _readInt(json['blockedUsersCount']),
    );
  }
}

class AdminRole {
  final int id;
  final String roleName;

  const AdminRole({
    required this.id,
    required this.roleName,
  });

  factory AdminRole.fromJson(Map<String, dynamic> json) {
    return AdminRole(
      id: _readInt(json['id']),
      roleName: _readString(json['roleName']),
    );
  }
}

class AdminUser {
  final int accountId;
  final int? userId;
  final String email;
  final int roleId;
  final String roleName;
  final bool isBlocked;
  final String? lastName;
  final String? firstName;
  final String? patronymic;
  final String registrationDate;

  const AdminUser({
    required this.accountId,
    required this.userId,
    required this.email,
    required this.roleId,
    required this.roleName,
    required this.isBlocked,
    required this.lastName,
    required this.firstName,
    required this.patronymic,
    required this.registrationDate,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      accountId: _readInt(json['accountId']),
      userId: _readNullableInt(json['userId']),
      email: _readString(json['email']),
      roleId: _readInt(json['roleId']),
      roleName: _readString(json['role']),
      isBlocked: _readBool(json['isBlocked']),
      lastName: _readNullableString(json['lastName']),
      firstName: _readNullableString(json['firstName']),
      patronymic: _readNullableString(json['patronymic']),
      registrationDate: _readString(json['registrationDate']),
    );
  }

  String get fullName {
    final parts = [
      lastName,
      firstName,
      patronymic,
    ].where((value) => value != null && value.trim().isNotEmpty).toList();

    if (parts.isEmpty) {
      return email;
    }

    return parts.join(' ');
  }

  String get statusTitle {
    return isBlocked ? 'Заблокирован' : 'Активен';
  }
}

class AdminAuditLog {
  final int id;
  final String actionName;
  final String entityName;
  final int? entityId;
  final String? oldValue;
  final String? newValue;
  final String actionDate;
  final String? accountEmail;

  const AdminAuditLog({
    required this.id,
    required this.actionName,
    required this.entityName,
    required this.entityId,
    required this.oldValue,
    required this.newValue,
    required this.actionDate,
    required this.accountEmail,
  });

  factory AdminAuditLog.fromJson(Map<String, dynamic> json) {
    return AdminAuditLog(
      id: _readInt(json['id']),
      actionName: _readString(json['actionName']),
      entityName: _readString(json['entityName']),
      entityId: _readNullableInt(json['entityId']),
      oldValue: _readNullableString(json['oldValue']),
      newValue: _readNullableString(json['newValue']),
      actionDate: _readString(json['actionDate']),
      accountEmail: _readNullableString(json['accountEmail']),
    );
  }
}

class AdminBackupFile {
  final String fileName;
  final int sizeBytes;
  final String createdAt;
  final String modifiedAt;
  final String extension;

  const AdminBackupFile({
    required this.fileName,
    required this.sizeBytes,
    required this.createdAt,
    required this.modifiedAt,
    required this.extension,
  });

  factory AdminBackupFile.fromJson(Map<String, dynamic> json) {
    return AdminBackupFile(
      fileName: _readString(json['fileName']),
      sizeBytes: _readInt(json['sizeBytes']),
      createdAt: _readString(json['createdAt']),
      modifiedAt: _readString(json['modifiedAt']),
      extension: _readString(json['extension']),
    );
  }

  String get sizeTitle {
    if (sizeBytes < 1024) {
      return '$sizeBytes Б';
    }

    if (sizeBytes < 1024 * 1024) {
      final kb = sizeBytes / 1024;
      return '${kb.toStringAsFixed(1)} КБ';
    }

    final mb = sizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(2)} МБ';
  }
}


class AdminTemplate {
  final int id;
  final String templateName;
  final String chartType;
  final String colorScheme;
  final String? description;
  final bool isActive;

  const AdminTemplate({
    required this.id,
    required this.templateName,
    required this.chartType,
    required this.colorScheme,
    required this.description,
    required this.isActive,
  });

  factory AdminTemplate.fromJson(Map<String, dynamic> json) {
    return AdminTemplate(
      id: _readInt(json['id']),
      templateName: _readString(json['templateName']),
      chartType: _readString(json['chartType']),
      colorScheme: _readString(json['colorScheme']),
      description: _readNullableString(json['description']),
      isActive: _readBool(json['isActive']),
    );
  }

  String get chartTypeTitle {
    switch (chartType) {
      case 'bar':
        return 'Столбчатая';
      case 'line':
        return 'Линейная';
      case 'pie':
        return 'Круговая';
      case 'doughnut':
        return 'Кольцевая';
      case 'card':
        return 'Карточки';
      default:
        return chartType.isEmpty ? 'Не указан' : chartType;
    }
  }

  String get statusTitle {
    return isActive ? 'Активен' : 'Отключен';
  }
}

int _readInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _readNullableInt(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString());
}

String _readString(dynamic value) {
  return value?.toString().trim() ?? '';
}

String? _readNullableString(dynamic value) {
  final text = value?.toString().trim();

  if (text == null || text.isEmpty) {
    return null;
  }

  return text;
}

bool _readBool(dynamic value) {
  if (value is bool) {
    return value;
  }

  final text = value?.toString().trim().toLowerCase();

  return text == 'true' || text == '1' || text == 'yes';
}
