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
  audit,
}

class AdminState extends Equatable {
  final AdminStatus status;
  final AdminSection section;
  final AdminDashboardStats? dashboard;
  final List<AdminUser> users;
  final List<AdminRole> roles;
  final List<AdminAuditLog> auditLogs;
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
        auditLogs.isEmpty;
  }

  bool get hasAnyData {
    return dashboard != null || users.isNotEmpty || auditLogs.isNotEmpty;
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
        searchQuery,
        message,
        messageIsError,
      ];
}