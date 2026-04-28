part of 'admin_bloc.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object?> get props => [];
}

class AdminStarted extends AdminEvent {
  const AdminStarted();
}

class AdminRefreshRequested extends AdminEvent {
  const AdminRefreshRequested();
}

class AdminSectionChanged extends AdminEvent {
  final AdminSection section;

  const AdminSectionChanged({
    required this.section,
  });

  @override
  List<Object?> get props => [section];
}

class AdminUserSearchChanged extends AdminEvent {
  final String query;

  const AdminUserSearchChanged({
    required this.query,
  });

  @override
  List<Object?> get props => [query];
}

class AdminUserRoleChanged extends AdminEvent {
  final int accountId;
  final int roleId;

  const AdminUserRoleChanged({
    required this.accountId,
    required this.roleId,
  });

  @override
  List<Object?> get props => [
        accountId,
        roleId,
      ];
}

class AdminUserBlockStatusChanged extends AdminEvent {
  final int accountId;
  final bool isBlocked;

  const AdminUserBlockStatusChanged({
    required this.accountId,
    required this.isBlocked,
  });

  @override
  List<Object?> get props => [
        accountId,
        isBlocked,
      ];
}


class AdminTemplateCreateRequested extends AdminEvent {
  final String templateName;
  final String chartType;
  final String colorScheme;
  final String? description;
  final bool isActive;

  const AdminTemplateCreateRequested({
    required this.templateName,
    required this.chartType,
    required this.colorScheme,
    required this.description,
    required this.isActive,
  });

  @override
  List<Object?> get props => [
        templateName,
        chartType,
        colorScheme,
        description,
        isActive,
      ];
}

class AdminTemplateUpdateRequested extends AdminEvent {
  final int id;
  final String templateName;
  final String chartType;
  final String colorScheme;
  final String? description;
  final bool isActive;

  const AdminTemplateUpdateRequested({
    required this.id,
    required this.templateName,
    required this.chartType,
    required this.colorScheme,
    required this.description,
    required this.isActive,
  });

  @override
  List<Object?> get props => [
        id,
        templateName,
        chartType,
        colorScheme,
        description,
        isActive,
      ];
}

class AdminTemplateDeleteRequested extends AdminEvent {
  final int id;

  const AdminTemplateDeleteRequested({
    required this.id,
  });

  @override
  List<Object?> get props => [id];
}

class AdminBackupCreateRequested extends AdminEvent {
  final String? backupName;

  const AdminBackupCreateRequested({
    this.backupName,
  });

  @override
  List<Object?> get props => [backupName];
}

class AdminBackupRestoreRequested extends AdminEvent {
  final String fileName;

  const AdminBackupRestoreRequested({
    required this.fileName,
  });

  @override
  List<Object?> get props => [fileName];
}
