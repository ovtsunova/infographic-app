part of 'admin_bloc.dart';

enum AdminStatus {
  initial,
  loading,
  ready,
  submitting,
  failure,
}

enum AdminSection {
  overview,
  users,
  templates,
  audit,
  backups,
}

class AdminState extends Equatable {
  final AdminStatus status;
  final AdminSection section;
  final AdminDashboardStats? dashboard;
  final List<AdminUser> users;
  final List<AdminRole> roles;
  final List<AdminAuditLog> auditLogs;
  final List<AdminTemplate> templates;
  final List<AdminBackupFile> backupFiles;
  final String searchQuery;
  final String? message;
  final bool messageIsError;

  const AdminState({
    required this.status,
    required this.section,
    required this.dashboard,
    required this.users,
    required this.roles,
    required this.auditLogs,
    required this.templates,
    required this.backupFiles,
    required this.searchQuery,
    required this.message,
    required this.messageIsError,
  });

  const AdminState.initial()
      : status = AdminStatus.initial,
        section = AdminSection.overview,
        dashboard = null,
        users = const [],
        roles = const [],
        auditLogs = const [],
        templates = const [],
        backupFiles = const [],
        searchQuery = '',
        message = null,
        messageIsError = false;

  bool get isBusy {
    return status == AdminStatus.loading || status == AdminStatus.submitting;
  }

  bool get isInitialLoading {
    return (status == AdminStatus.initial || status == AdminStatus.loading) &&
        dashboard == null &&
        users.isEmpty &&
        auditLogs.isEmpty &&
        templates.isEmpty &&
        backupFiles.isEmpty;
  }

  bool get hasAnyData {
    return dashboard != null ||
        users.isNotEmpty ||
        auditLogs.isNotEmpty ||
        templates.isNotEmpty ||
        backupFiles.isNotEmpty;
  }

  List<AdminUser> get filteredUsers {
    final query = searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return users;
    }

    return users.where((user) {
      final text = [
        user.accountId.toString(),
        user.fullName,
        user.email,
        user.roleName,
        user.statusTitle,
        user.registrationDate,
      ].join(' ').toLowerCase();

      return text.contains(query);
    }).toList();
  }

  AdminState copyWith({
    AdminStatus? status,
    AdminSection? section,
    AdminDashboardStats? dashboard,
    List<AdminUser>? users,
    List<AdminRole>? roles,
    List<AdminAuditLog>? auditLogs,
    List<AdminTemplate>? templates,
    List<AdminBackupFile>? backupFiles,
    String? searchQuery,
    String? message,
    bool clearMessage = false,
    bool? messageIsError,
  }) {
    return AdminState(
      status: status ?? this.status,
      section: section ?? this.section,
      dashboard: dashboard ?? this.dashboard,
      users: users ?? this.users,
      roles: roles ?? this.roles,
      auditLogs: auditLogs ?? this.auditLogs,
      templates: templates ?? this.templates,
      backupFiles: backupFiles ?? this.backupFiles,
      searchQuery: searchQuery ?? this.searchQuery,
      message: clearMessage ? null : message ?? this.message,
      messageIsError: clearMessage
          ? false
          : messageIsError ?? this.messageIsError,
    );
  }

  @override
  List<Object?> get props => [
        status,
        section,
        dashboard,
        users,
        roles,
        auditLogs,
        templates,
        backupFiles,
        searchQuery,
        message,
        messageIsError,
      ];
}
